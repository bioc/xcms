## Unsorted utility functions.
#' @include DataClasses.R

############################################################
## valueCount2ScanIndex
##
#' @title Create index vector for internal C calls
#'
#' @description Simple helper function that converts the number of values
#'     per scan/spectrum to an integer vector that can be passed to the base
#'     xcms functions/downstream C functions.
#'
#' @param valCount Numeric vector representing the number of values per
#'     spectrum.
#'
#' @return An integer vector with the index (0-based) in the mz or intensity
#'     vectors indicating the start of a spectrum.
#'
#' @author Johannes Rainer
#'
#' @noRd
valueCount2ScanIndex <- function(valCount){
    ## Convert into 0 based.
    valCount <- cumsum(valCount)
    return(as.integer(c(0, valCount[-length(valCount)])))
}

############################################################
## useOriginalCode
##
## Simple function allowing the user to enable using the orignal
## code instead of the new implementations.
## This sets options.
##
#' @title Enable usage of old xcms code
#'
#' @description
#'
#' This function allows to enable the usage of old, partially deprecated
#' code from xcms by setting a corresponding global option. See details
#' for functions affected.
#'
#' @note
#'
#' For parallel processing using the SOCKS method (e.g. by [SnowParam()] on
#' Windows computers) this option might not be passed to the individual R
#' processes performing the calculations. In such cases it is suggested to
#' specify the option manually and system-wide by adding the line
#' `options(XCMSuseOriginalCode = TRUE)` in a file called *.Rprofile* in the
#' folder in which new R processes are started (usually the user's
#' home directory; to ensure that the option is correctly read add a new line
#' to the file too). See also [Startup] from the base R documentation on how to
#' specify system-wide options for R.
#'
#' Usage of old code is strongly dicouraged. This function is thought
#' to be used mainly in the transition phase from xcms to xcms version 3.
#'
#' @details
#'
#' The functions/methods that are affected by this option are:
#'
#' - [do_findChromPeaks_matchedFilter]: use the original
#'   code that iteratively creates a subset of the binned (profile)
#'   matrix. This is helpful for computers with limited memory or
#'   matchedFilter settings with a very small bin size.
#' - [getPeaks]
#'
#' @param x `logical(1)` to specify whether or not original
#'     old code should be used in corresponding functions. If not provided the
#'     function simply returns the value of the global option.
#'
#' @return `logical(1)` indicating whether old code is being used.
#'
#' @md
#'
#' @author Johannes Rainer
useOriginalCode <- function(x) {
    if (missing(x)) {
        res <- options()$XCMSuseOriginalCode
        if (is.null(res))
            return(FALSE)
        return(res)
    }
    if (!is.logical(x))
        stop("'x' has to be logical.")
    options(XCMSuseOriginalCode = x[1])
    return(options()$XCMSuseOriginalCode)
}

#' @title Copy the content from an environment to another one
#'
#' @description This function copies the content of an environment into another
#'     one.
#'
#' @param env environment from which to copy.
#'
#' @param inheritLocks logical(1) whether the locking status should be copied
#'     too.
#'
#' @return an env.
#'
#' @noRd
.copy_env <- function(env, inheritLocks = FALSE) {
    ## new_e <- new.env(parent = emptyenv())
    ## eNames <- ls(env, all.names = TRUE)
    ## if (length(eNames) > 0) {
    ##     for (eN in eNames) {
    ##         new_e[[eN]] <- env[[eN]]
    ##     }
    ## }
    new_e <- as.environment(as.list(env, all.names = TRUE))
    if (inheritLocks) {
        if (environmentIsLocked(env))
            lockEnvironment(new_e)
    }
    return(new_e)
}

############################################################
## .createProfileMatrix
#' @title Create the profile matrix
#'
#' @description This function creates a \emph{profile} matrix, i.e. a rt times
#'     m/z matrix of aggregated intensity values with values aggregated within
#'     bins along the m/z dimension.
#'
#' @details This is somewhat the successor function for the deprecated
#'     \code{profBin} methods (\code{profBinM}, \code{profBinLinM},
#'     \code{profBinLinBaseM} and \code{profIntLin}).
#'
#' @param mz Numeric representing the m/z values across all scans/spectra.
#'
#' @param int Numeric representing the intensity values across all
#'     scans/spectra.
#'
#' @param valsPerSpect Numeric representing the number of measurements for each
#'     scan/spectrum.
#'
#' @param method A character string specifying the profile matrix generation
#'     method. Allowed are \code{"bin"}, \code{"binlin"},
#'     \code{"binlinbase"} and \code{"intlin"}.
#'
#' @param step Numeric specifying the size of the m/z bins.
#'
#' @param baselevel Numeric specifying the base value.
#'
#' @param basespace Numeric.
#'
#' @param mzrange. numeric(2) optionally specifying the mz value range
#'     for binning. This is to adopt the old profStepPad<- method used for
#'     obiwarp retention time correction that did the binning from
#'     whole-number limits.
#'
#' @param returnBreaks logical(1): hack to return the breaks of the bins.
#'     Setting this to TRUE causes the function to return a \code{list} with
#'     elements \code{"$profMat"} and \code{"breaks"}.
#'
#' @param baseValue numeric(1) defining the value to be returned if no signal
#'     was found in the corresponding bin. Defaults to 0 for backward
#'     compatibility.
#'
#' @noRd
.createProfileMatrix <- function(mz, int, valsPerSpect,
                                 method, step = 0.1, baselevel = NULL,
                                 basespace = NULL,
                                 mzrange. = NULL,
                                 returnBreaks = FALSE,
                                 baseValue = 0) {
    profMeths <- c("bin", "binlin", "binlinbase", "intlin")
    names(profMeths) <- c("none", "lin", "linbase", "intlin")
    method <- match.arg(method, profMeths)
    impute <- names(profMeths)[profMeths == method]
    brks <- NULL

    if (length(mzrange.) != 2) {
        mrange <- range(mz, na.rm = TRUE)
        mzrange. <- c(floor(mrange[1] / step) * step,
                      ceiling(mrange[2] / step) * step)
    }
    mass <- seq(mzrange.[1], mzrange.[2], by = step)
    mlength <- length(mass)
    ## Calculate the "real" bin size; old xcms code oddity that that's different
    ## from step.
    bin_size <- (mass[mlength] - mass[1]) / (mlength - 1)
    ## Define the breaks.
    toIdx <- cumsum(valsPerSpect)
    fromIdx <- c(1L, toIdx[-length(toIdx)] + 1L)
    shiftBy <- TRUE
    binFromX <- min(mass)
    binToX <- max(mass)
    brks <- breaks_on_nBins(fromX = binFromX, toX = binToX,
                            nBins = mlength, shiftByHalfBinSize = TRUE)
    ## for profIntLinM we have to use the old code.
    if (impute == "intlin") {
        profFun <- "profIntLinM"
        profp <- list()
        scanindex <- valueCount2ScanIndex(valsPerSpect)
        buf <- do.call(profFun, args = list(mz, int,
                                            scanindex, mlength,
                                            mass[1], mass[mlength],
                                            TRUE))
    } else {
        ## Binning the data.
        binRes <- binYonX(mz, int,
                          breaks = brks,
                          fromIdx = fromIdx,
                          toIdx = toIdx,
                          baseValue = ifelse(impute == "none", yes = baseValue,
                                             no = NA),
                          sortedX = TRUE,
                          returnIndex = FALSE,
                          returnX = FALSE
                          )
        if (length(toIdx) == 1)
            binRes <- list(binRes)
        ## Missing value imputation.
        if (impute == "linbase") {
            ## need arguments distance and baseValue.
            if (length(basespace) > 0) {
                if (!is.numeric(basespace))
                    stop("'basespace' has to be numeric!")
                distance <- floor(basespace[1] / bin_size)
            } else {
                distance <- floor(0.075 / bin_size)
            }
            if (length(baselevel) > 0) {
                if (!is.numeric(baselevel))
                    stop("'baselevel' has to be numeric!")
                baseValue <- baselevel
            } else {
                baseValue <- min(int, na.rm = TRUE) / 2
            }
        } else {
            distance <- 0
            baseValue <- 0
        }
        if (method == "none") {
            ## binVals <- lapply(binRes, function(z) z$y)
            binVals <- binRes
        } else {
            binVals <- lapply(binRes, function(z) {
                imputeLinInterpol(z$y, method = impute, distance = distance,
                                  noInterpolAtEnds = TRUE,
                                  baseValue = baseValue)
            })
        }
        buf <- base::do.call(cbind, binVals)
    }
    if (returnBreaks)
        buf <- list(profMat = buf, breaks = brks)
    buf
}

#' @description This function creates arbitrary IDs for features.
#'
#' @param prefix character(1) with the prefix to be added to the ID.
#'
#' @param x integer(1) with the number of IDs that should be generated.
#'
#' @noRd
.featureIDs <- function(x, prefix = "FT", from = 1L) {
    sprintf(paste0(prefix, "%0", ceiling(log10(x + from)), "d"),
            seq(from = from, length.out = x))
}

#' @title Weighted mean around maximum
#'
#' @description Calculate a weighted mean of the values around the value with
#'     the largest weight. \code{x} could e.g. be mz values and \code{w} the
#'     corresponding intensity values.
#'
#' @param x \code{numeric} vector from which the weighted mean should be
#'     calculated.
#'
#' @param w \code{numeric} of same length than \code{x} with the weights.
#'
#' @param i \code{integer(1)} defining the number of data points left and right
#'     of the index with the largest weight that should be considered for the
#'     weighted mean calculation.
#'
#' @return The weighted mean value.
#'
#' @author Johannes Rainer
#'
#' @noRd
#'
#' @examples
#'
#' mz <- c(124.0796, 124.0812, 124.0828, 124.0843, 124.0859, 124.0875,
#'     124.0890, 124.0906, 124.0922, 124.0938, 124.0953, 124.0969)
#' ints <- c(10193.8, 28438.0, 56987.6, 85107.6, 102531.6, 104262.6,
#'     89528.8, 61741.2, 33485.8, 14146.6, 5192.2, 1630.2)
#'
#' plot(mz, ints)
#'
#' ## What would be found by the max:
#' abline(v = mz[which.max(ints)], col = "grey")
#' ## What does the weighted mean around apex return:
#' abline(v = weightedMeanAroundApex(mz, ints, i = 2), col = "blue")
weightedMeanAroundApex <- function(x, w = rep(1, length(x)), i = 1) {
    max_idx <- which.max(w)
    seq_idx <- max(1, max_idx - i):min(length(x), max_idx + i)
    weighted.mean(x[seq_idx], w[seq_idx])
}

#' @title DEPRECATED: Create a plot that combines a XIC and a mz/rt 2D plot for one sample
#'
#' @description
#'
#' **UPDATE**: please use `plot()` from the `MsExperiment` or
#' `plot(x, type = "XIC")` from the `MSnbase` package instead. See examples
#' in the vignette for more information.
#'
#' The `plotMsData` creates a plot that combines an (base peak )
#' extracted ion chromatogram on top (rt against intensity) and a plot of
#' rt against m/z values at the bottom.
#'
#' @param x `data.frame` such as returned by the [extractMsData()] function.
#'     Only a single `data.frame` is supported.
#'
#' @param main `character(1)` specifying the title.
#'
#' @param cex `numeric(1)` defining the size of points. Passed directly to the
#'     `plot` function.
#'
#' @param mfrow `numeric(2)` defining the plot layout. This will be passed
#'     directly to `par(mfrow = mfrow)`. See `par` for more information. Setting
#'     `mfrow = NULL` avoids calling `par(mfrow = mfrow)` hence allowing to
#'     pre-define the plot layout.
#'
#' @param grid.color a color definition for the grid line (or `NA` to skip
#'     creating them).
#'
#' @param colramp a *color ramp palette* to be used to color the data points
#'     based on their intensity. See argument `col.regions` in
#'     [lattice::level.colors] documentation.
#'
#' @author Johannes Rainer
#'
#' @md
#'
plotMsData <- function(x, main = "", cex = 1, mfrow = c(2, 1),
                       grid.color = "lightgrey",
                       colramp = colorRampPalette(
                           rev(brewer.pal(9, "YlGnBu")))) {
    .Deprecated(msg = paste0("'plotMsData' is deprecated. Please use ",
                             "'plot(x, type = \"XIC\") instead."))
    if (length(mfrow) == 2)
        par(mfrow = mfrow)
    par(mar = c(0, 4, 2, 1))
    x_split <- split(x$i, f = x$rt)
    ints <- unlist(lapply(x_split, function(z) max(z)))
    brks <- do.breaks(range(x$i), nint = 256)
    cols <- level.colors(ints, at = brks, col.regions = colramp)
    plot(as.numeric(names(ints)), ints, main = main, xlab = "", xaxt = "n",
         ylab = "", las = 2, pch = 21, bg = cols, col = "grey", cex = cex)
    mtext(side = 4, line = 0, "intensity", cex = par("cex.lab"))
    grid(col = grid.color)
    par(mar = c(3.5, 4, 0, 1))
    cols <- level.colors(x$i, at = brks, col.regions = colramp)
    plot(x$rt, x$mz, main = "", pch = 21, bg = cols, col = "grey",
         xlab = "", ylab = "", yaxt = "n", cex = cex)
    axis(side = 2, las = 2)
    grid(col = grid.color)
    mtext(side = 1, line = 2.5, "retention time", cex = par("cex.lab"))
    mtext(side = 4, line = 0, "mz", cex = par("cex.lab"))
}

#' @title Calculate relative log abundances
#'
#' @description
#'
#' `rla` calculates the relative log abundances (RLA, see reference) on a
#' `numeric` vector.
#'
#' @details The RLA is defines as the (log) abundance of an analyte relative
#'     to the median across all abundances of the same group.
#'
#' @param x `numeric` (for `rla`) or `matrix` (for `rowRla`) with the
#'     abundances (in natural scale) on which the RLA should be calculated.
#'
#' @param group `factor`, `numeric` or `character` with the same length
#'     than `x` that groups values in `x`. If omitted all values are considered
#'     to be from the same group.
#'
#' @param log.transform `logical(1)` whether `x` should be log2 transformed.
#'     Set to `log.transform = FALSE` if `x` is already in log scale.
#'
#' @return `numeric` of the same length than `x` (for `rla`) or `matrix` with
#'     the same dimensions than `x` (for `rowRla`).
#'
#' @rdname rla
#'
#' @author Johannes Rainer
#'
#' @md
#'
#' @references
#'
#' De Livera AM, Dias DA, De Souza D, Rupasinghe T, Pyke J, Tull D, Roessner U,
#' McConville M, Speed TP. Normalizing and integrating metabolomics data.
#' *Anal Chem* 2012 Dec 18;84(24):10768-76.
#'
#' @examples
#'
#' x <- c(3, 4, 5, 1, 2, 3, 7, 8, 9)
#'
#' grp <- c(1, 1, 1, 2, 2, 2, 3, 3, 3)
#'
#' rla(x, grp)
rla <- function(x, group, log.transform = TRUE) {
    if (missing(group))
        group <- rep_len(1, length(x))
    if (length(x) != length(group))
        stop("length of 'x' has to match length of 'group'")
    if (!is.factor(group))
	group <- factor(group, levels = unique(group))
    ## Calculate group medians.
    if (log.transform)
        x <- log2(x)
    grp_meds <- unlist(lapply(split(x, group), median, na.rm = TRUE))
    x - grp_meds[group]
}

#' `rowRla` calculates row-wise RLAs.
#'
#' @rdname rla
#'
#' @md
rowRla <- function(x, group, log.transform = TRUE) {
    t(apply(x, MARGIN = 1, rla, group = group, log.transform = log.transform))
}

#' @title Identify rectangles overlapping in a two-dimensional space
#'
#' @description
#'
#' `.rect_overlap` identifies rectangles overlapping in a two dimensional
#' space.
#'
#' @return `list` with indices of overlapping elements.
#'
#' @noRd
#'
#' @author Johannes Rainer
.rect_overlap <- function(xleft, xright, ybottom, ytop) {
    if (missing(xleft) | missing(xright) | missing(ybottom) | missing(ytop))
        stop("'xleft', 'xright', 'ybottom' and 'ytop' are required parameters")
    if (length(unique(c(length(xleft), length(xright), length(ybottom),
                        length(ytop)))) != 1)
        stop("'xleft', 'xright', 'ybottom' and 'ytop' have to have the same",
             " length")
    .overlap <- function(x1, x2, xs1, xs2) {
        x1 <= xs2 & x2 >= xs1
    }
    nr <- length(xleft)
    ovlap <- vector("list", nr)
    ## Calculate overlap of any element with any other. Need only to compare
    ## element i with i:length.
    for (i in seq_len(nr)) {
        other_idx <- i:nr
        do_ovlap <- .overlap(xleft[i], xright[i],
                             xleft[other_idx], xright[other_idx]) &
            .overlap(ybottom[i], ytop[i],
                     ybottom[other_idx], ytop[other_idx])
        ovlap[[i]] <- other_idx[do_ovlap]
    }
    ovlap <- ovlap[lengths(ovlap) > 1]
    ovlap_merged <- list()
    ovlap_remain <- ovlap
    ## Combine grouped features if the have features in common
    while (length(ovlap_remain)) {
        current <- ovlap_remain[[1]]
        ovlap_remain <- ovlap_remain[-1]
        if (length(ovlap_remain) > 0) {
            ## Check if we have any overlap with any other merged group
            also_here <- vapply(ovlap_remain, function(z) any(z %in% current),
                                logical(1), USE.NAMES = FALSE)
            ## Join them with current.
            current <- sort(unique(c(current, unlist(ovlap_remain[also_here]))))
            ovlap_remain <- ovlap_remain[!also_here]
        }
        ## Check if current is in any of the already joined ones, if so, merge
        also_here <- which(vapply(ovlap_merged, function(z) any(z %in% current),
                                  logical(1), USE.NAMES = FALSE))
        if (length(also_here)) {
            ovlap_merged[[also_here[1]]] <-
                sort(unique(c(unlist(ovlap_merged[also_here]), current)))
            ## In case also remove all others - shouldn't really happen...
            if (length(also_here) > 1)
                ovlap_merged <- ovlap_merged[-also_here[-1]]
        } else
            ovlap_merged[[length(ovlap_merged) + 1]] <- current
    }
    ovlap_merged
}

#' Calculate a range of values adding a part per million to it. The minimum
#' will be the minimum - ppm/2, the maximum the maximum + ppm/2
#'
#' @param x `numeric`
#'
#' @param ppm `numeric(1)`
#'
#' @return `numeric(2)` with the range +/- ppm
#'
#' @noRd
#'
#' @author Johannes Rainer
.ppm_range <- function(x, ppm = 0) {
    x <- range(x)
    x[1] <- x[1] - x[1] * ppm / 2e6
    x[2] <- x[2] + x[2] * ppm / 2e6
    x
}

#' Simple helper to insert column(s) in a matrix.
#'
#' @param x `matrix`
#'
#' @param pos `integer()` with positions (columns) where a column should be
#'     inserted in `x`.
#'
#' @param val `vector` or `list` with the elements to insert.
#'
#' @return `matrix`
#'
#' @author Johannes Rainer
#'
#' @noRd
#'
#' @examples
#'
#' mat <- matrix(1:100, ncol = 5)
#'
#' ## Insert a column at position 3, containing a single value.
#' .insertColumn(mat, pos = 3, 5)
#'
#' ## Insert columns at positions 2 and 4 containing the same sequence of
#' ## values
#' .insertColumn(mat, c(2, 4), list(101:120))
.insertColumn <- function(x, pos = integer(), val = NULL) {
    if (length(pos)) {
        if (length(val) == 1)
            val <- rep(val, length(pos))
        if (length(val) != length(pos))
            stop("length of 'pos' and 'val' have to match")
    }
    for (i in seq_along(pos)) {
        if (pos[i] == 1) {
            x <- cbind(val[[i]], x)
        } else {
            if (pos[i] == ncol(x))
                x <- cbind(x, val[[i]])
            else
                x <- cbind(x[, 1:(pos[i]-1)], val[[i]], x[, pos[i]:ncol(x)])
        }
    }
    x
}

#' helper to subset featureDefinitions based on provided chrom peak names and
#' update the peakidx.
#'
#' @param x `DataFrame` with feature definitions (such as returned by
#'     `featureDefinitions(object)`.
#'
#' @param original_names `character` with the original rownames (peak IDs) of
#'     the `chromPeaks` matrix **before** subsetting.
#'
#' @param subset_names `character` with the rownames (peak IDs) of the
#'     `chromPeaks` matrix **after** subsetting.
#'
#' @return updated feature definitions `DataFrame`.
#'
#' @author Johannes Rainer
#'
#' @md
#'
#' @noRd
.update_feature_definitions <- function(x, original_names, subset_names) {
    ## Skip if they are the same.
    if (length(original_names) == length(subset_names) &&
        all.equal(original_names, subset_names))
        return(x)
    f <- as.factor(rep(seq_len(length(x$peakidx)), lengths(x$peakidx)))
    x$peakidx <- unname(lapply(
        split(match(original_names[unlist(x$peakidx,
                                          use.names = FALSE)],
                    subset_names), f), function(z) z[!is.na(z)]))
    extractROWS(x, lengths(x$peakidx) > 0)
}

#' @description
#'
#' Combine `matrix` or `data.frame`s adding eventually missing columns filling
#' them with `NA`s.
#'
#' @param x `matrix` or `data.frame`.
#'
#' @param y `matrix` or `data.frame`.
#'
#' @md
#'
#' @author Johannes Rainer
#'
#' @noRd
.rbind_fill <- function(x, y) {
    cnx <- colnames(x)
    cny <- colnames(y)
    cn <- union(cnx, cny)
    mis_col <- setdiff(cn, colnames(x))
    for (mc in mis_col) {
        if (is.factor(y[, mc]))
            x <- cbind(x, tmp = as.factor(NA))
        else
            x <- cbind(x, tmp = as(NA, class(y[, mc])))
    }
    colnames(x) <- c(cnx, mis_col)
    mis_col <- setdiff(cn, colnames(y))
    for (mc in mis_col) {
        if (is.factor(x[, mc]))
            y <- cbind(y, tmp = as.factor(NA))
        else
            y <- cbind(y, tmp = as(NA, class(x[, mc])))
    }
    colnames(y) <- c(cny, mis_col)
    rbind(x, y[, colnames(x)])
}

#' @description
#'
#' Similar to the `IRanges::reduce` method, this function *joins* overlapping
#' ranges (e.g. m/z ranges or retention time ranges) to create unique and
#' disjoined (i.e. not overlapping) ranges.
#'
#' @param start `numeric` with start positions.
#'
#' @param end `numeric` with end positions.
#'
#' @return `matrix` with two columns containing the start and end values for
#'     the disjoined ranges. Note that the ranges are increasingly ordered.
#'
#' @author Johannes Rainer
#'
#' @md
#'
#' @noRd
#'
#' @examples
#'
#' mzmin <- c(2, 3, 4, 7)
#' mzmax <- c(2.5, 3.5, 4.2, 7.6)
#' .reduce(mzmin, mzmax)
#' .reduce(mzmin - 0.1, mzmax + 0.1)
#' .reduce(mzmin - 0.5, mzmax + 0.5)
.reduce <- function(start, end) {
    if (!length(start))
        return(matrix(ncol = 2, nrow = 0,
                      dimnames = list(NULL, c("start", "end"))))
    if (length(start) == 1) {
        return(cbind(start, end))
    }
    idx <- order(start, end)
    start <- start[idx]
    end <- end[idx]
    new_start <- new_end <- numeric(length(start))
    current_slice <- 1
    new_start[current_slice] <- start[1]
    new_end[current_slice] <- end[1]
    for (i in 2:length(start)) {
        if (start[i] <= new_end[current_slice]) {
            if (end[i] > new_end[current_slice])
                new_end[current_slice] <- end[i]
        } else {
            current_slice <- current_slice + 1
            new_start[current_slice] <- start[i]
            new_end[current_slice] <- end[i]
        }
    }
    idx <- 1:current_slice
    cbind(start = new_start[idx], end = new_end[idx])
}

#' @title Group overlapping ranges
#'
#' @description
#'
#' `groupOverlaps` identifies overlapping ranges in the input data and groups
#' them by returning their indices in `xmin` `xmax`.
#'
#' @param xmin `numeric` (same length than `xmax`) with the lower boundary of
#'     the range.
#'
#' @param xmax `numeric` (same length than `xmin`) with the upper boundary of
#'     the range.
#'
#' @return `list` with the indices of grouped elements.
#'
#' @author Johannes Rainer
#'
#' @md
#'
#' @examples
#'
#' x <- c(2, 12, 34.2, 12.4)
#' y <- c(3, 16, 35, 36)
#'
#' groupOverlaps(x, y)
groupOverlaps <- function(xmin, xmax) {
    tolerance <- sqrt(.Machine$double.eps)
    reduced_ranges <- .reduce(xmin, xmax)
    res <- vector("list", nrow(reduced_ranges))
    for (i in seq_along(res)) {
        res[[i]] <- which(xmin >= reduced_ranges[i, 1] - tolerance &
                          xmax <= reduced_ranges[i, 2] + tolerance)
    }
    res
}

.require_spectra <- function() {
    if (!requireNamespace("Spectra", quietly = TRUE))
        stop("Returning data as a 'Spectra' object requires the 'Spectra' ",
             "package to be installed. Please ",
             "install with 'BiocInstaller::install(\"Spectra\")'")
    else invisible(TRUE)
}

#' very efficient extractor for the featureData of an OnDiskMSnExp
#'
#' @param x `OnDiskMSnExp`.
#'
#' @author Johannes Rainer
#'
#' @noRd
.fdata <- function(x) {
    x@featureData@data
}

.i2index <- function(x, ids = character(), name = character()) {
    if (is.character(x))
        x <- match(x, ids)
    if (is.logical(x)) {
        if (length(ids) && length(ids) != length(x))
            stop("Length of '", name, "' has to be equal to ", length(ids), ".")
        x <- which(x)
    }
    if (is.numeric(x))
        x <- as.integer(x)
    if (length(ids) && any(is.na(x)) || (any(x < 1) || any(x > length(ids))))
        stop("'", name, "' out of bounds")
    x
}

.match_last <- function(x, table, nomatch = NA_integer_) {
    mtch <- match(x, rev(table), nomatch = NA_integer_)
    mtch <- length(table) - mtch + 1
    mtch[is.na(mtch)] <- nomatch
    mtch
}

#' @description
#'
#' Function to extract EICs. In contrast to the other versions, this one
#' allows to extract `Chromatogram` for all MS levels at the same time.
#' The EIC is defined by a chrom peak matrix `pks` (column `"rtmin"`,
#' `"rtmax"`, `"mzmin"` and `"mzmax"`). Additional required parameters are
#' the MS level of spectra and EICs. Further selection/mapping of spectra
#' with m/z-rt regions can be defined with the parameter `tmz` and `pks_tmz`
#' which can e.g. be the *isolation window target m/z* for spectra and EICs.
#' The latter is important for MS2 data, since that could be generated using
#' different scanning windows (SWATH): only MS2 spectra from the matching
#' isolation window will be used for chromatogram generation.
#'
#' See also `.old_chromatogram_sample` in *MsExperiment-functions.R* for an
#' alternative implementation.
#'
#' @param pd `list` of peaks matrices (e.g. returned by `Spectra::peaksData`).
#'
#' @param rt `numeric` with retention times of spectra.
#'
#' @param msl `integer` with the MS levels for the spectra.
#'
#' @param tmz `numeric` with the isolation window target m/z for each spectrum
#'     (for DIA MS2 data).
#'
#' @param pks `matrix` with columns `"rtmin"`, `"rtmax"`, `"mzmin"`, `"mzmax"`
#'     for which the
#'
#' @param pks_msl `integer` with the MS levels for the regions from which the
#'     chromatograms should be extracted.
#'
#' @param pks_tmz `numeric` with the isolation window target m/z in which
#'     the (MS2) chromatographic peak was detected. For `pks_msl > 1L` only
#'     spectra with their `isolationWindowTargetMz` being equal to this value
#'     are considered for the chromatogram extraction. Set to
#'     `pks_tmz = NA_real_` to use **all** spectra with matching MS level and
#'     ignore the isolation window.
#'
#' @param file_idx `integer(1)` allowing to optionally set the index of the
#'     file the EIC is from (parameter `fromFile`).
#'
#' @return `list` of `MSnbase::Chromatogram` objects.
#'
#' @author Johannes Rainer, Nir Shachaf
#'
#' @noRd
.chromatograms_for_peaks <- function(pd, rt, msl, file_idx = 1L,
                                     tmz = rep(NA_real_, length(pd)), pks,
                                     pks_msl,
                                     pks_tmz = rep(NA_real_, nrow(pks)),
                                     aggregationFun = "sum") {
    nr <- nrow(pks)
    pks_msl <- as.integer(pks_msl)
    FUN <- switch(aggregationFun,
                  "sum" = getFunction("sumi"),
                  "max" = getFunction("maxi"),
                  getFunction(aggregationFun))
    empty_chrom <- MSnbase::Chromatogram(
                                fromFile = file_idx,
                                aggregationFun = aggregationFun,
                                intensity = numeric(),
                                rtime = numeric())
    res <- list(empty_chrom)[rep(1L, nr)]
    rtc <- c("rtmin", "rtmax")
    mzc <- c("mzmin", "mzmax")
    for (i in seq_len(nr)) {
        slot(res[[i]], "filterMz", check = FALSE) <- pks[i, mzc]
        slot(res[[i]], "mz", check = FALSE) <- pks[i, mzc]
        slot(res[[i]], "msLevel", check = FALSE) <- pks_msl[i]
        ## if pks_msl > 1: precursor m/z has to match!
        keep <- between(rt, pks[i, rtc]) & msl == pks_msl[i]
        if (pks_msl[i] > 1L && !is.na(pks_tmz[i])) {
            ## for DIA MS2: spectra have to match the isolation window.
            keep <- keep & tmz %in% pks_tmz[i]
        }
        keep <- which(keep)             # the get rid of `NA`.
        if (length(keep)) {
            ## Aggregate intensities.
            slot(res[[i]], "intensity", check = FALSE) <-
                vapply(pd[keep], function(z) {
                    FUN(z[between(z[, "mz"], pks[i, mzc]), "intensity"])
            }, numeric(1L))
            slot(res[[i]], "rtime", check = FALSE) <- rt[keep]
        }
    }
    res
}

## @jo TODO LLL replace that with an implementation in C.
## Note: this function silently drops retention times for which no intensity-mz
## pair was measured.
.rawMat <- function(mz, int, scantime, valsPerSpect, mzrange = numeric(),
                    rtrange = numeric(), scanrange = numeric(),
                    log = FALSE) {
    if (length(rtrange) >= 2) {
        rtrange <- range(rtrange)
        ## Fix for issue #267. rtrange outside scanrange causes scanrange
        ## being c(Inf, -Inf)
        scns <- which((scantime >= rtrange[1]) & (scantime <= rtrange[2]))
        if (!length(scns))
            return(matrix(
                nrow = 0, ncol = 3,
                dimnames = list(character(), c("time", "mz", "intensity"))))
        scanrange <- range(scns)
    }
    if (length(scanrange) < 2)
        scanrange <- c(1, length(valsPerSpect))
    else scanrange <- range(scanrange)
    if (!all(is.finite(scanrange)))
        stop("'scanrange' does not contain finite values")
    if (!all(is.finite(mzrange)))
        stop("'mzrange' does not contain finite values")
    if (!all(is.finite(rtrange)))
        stop("'rtrange' does not contain finite values")
    if (scanrange[1] == 1)
        startidx <- 1
    else
        startidx <- sum(valsPerSpect[1:(scanrange[1] - 1)]) + 1
    endidx <- sum(valsPerSpect[1:scanrange[2]])
    scans <- rep(scanrange[1]:scanrange[2],
                 valsPerSpect[scanrange[1]:scanrange[2]])
    masses <- mz[startidx:endidx]
    massidx <- 1:length(masses)
    if (length(mzrange) >= 2) {
        mzrange <- range(mzrange)
        massidx <- massidx[(masses >= mzrange[1] & (masses <= mzrange[2]))]
    }
    int <- int[startidx:endidx][massidx]
    if (log && (length(int) > 0))
        int <- log(int + max(1 - min(int), 0))
    cbind(time = scantime[scans[massidx]],
          mz = masses[massidx],
          intensity = int)
}

#' Helper function to use the internal getEIC C call to extract (TIC) EIC
#' data.
#'
#' @noRd
.getEIC <- function(mz, int, scantime, valsPerSpect, mzrange = numeric(),
                    rtrange = numeric(), log = FALSE) {
    rtrange <- range(rtrange)
    scns <- which((scantime >= rtrange[1]) & (scantime <= rtrange[2]))
    if (!length(scns))
        return(matrix(
            nrow = 0, ncol = 3,
            dimnames = list(character(), c("time", "mz", "intensity"))))
    if (!all(is.finite(mzrange)))
        stop("'mzrange' does not contain finite values")
    if (!all(is.finite(rtrange)))
        stop("'rtrange' does not contain finite values")
    scanindex <- valueCount2ScanIndex(valsPerSpect)
    res <- .Call("getEIC", mz, int, scanindex, mzrange,
                 as.integer(range(scns) - 1L), as.integer(length(scanindex)),
                 PACKAGE = "xcms")
    cbind(rtime = scantime[scns],
          intensity = res$intensity)
}
