## Methods for MSnbase's OnDiskMSnExp and MSnExp objects.
#' @include DataClasses.R functions-OnDiskMSnExp.R do_findChromPeaks-functions.R


## Main roxygen documentation for the centWace feature detection is in
## DataClasses, before the definition of the CentWaveParam class.

## The centWave peak detection method for OnDiskMSnExp:
#' @title Chromatographic peak detection using the centWave method
#'
#' @description The \code{findChromPeaks,OnDiskMSnExp,CentWaveParam} method
#'     performs chromatographic peak detection using the \emph{centWave}
#'     algorithm on all samples from an \code{\link{OnDiskMSnExp}}
#'     object. \code{\link{OnDiskMSnExp}} objects encapsule all
#'     experiment specific data and load the spectra data (mz and intensity
#'     values) on the fly from the original files applying also all eventual
#'     data manipulations.
#'
#' @details Parallel processing (one process per sample) is supported and can
#'     be configured either by the \code{BPPARAM} parameter or by globally
#'     defining the parallel processing mode using the
#'     \code{\link{register}} method from the \code{BiocParallel}
#'     package.
#'
#' @param object For \code{findChromPeaks}: an
#'     \code{\link{OnDiskMSnExp}}  object containing the MS- and all
#'     other experiment-relevant data.
#'
#'     For all other methods: a parameter object.
#'
#' @param param An \code{CentWaveParam} object containing all settings for the
#'     centWave algorithm.
#'
#' @param BPPARAM A parameter class specifying if and how parallel processing
#'     should be performed. It defaults to \code{\link{bpparam}}.
#'     See documentation of the \code{BiocParallel} for more details. If
#'     parallel processing is enabled, peak detection is performed in parallel
#'     on several of the input samples.
#'
#' @param return.type Character specifying what type of object the method should
#'     return. Can be either \code{"XCMSnExp"} (default), \code{"list"} or
#'     \code{"xcmsSet"}.
#'
#' @param msLevel \code{integer(1)} defining the MS level on which the peak
#'     detection should be performed. Defaults to \code{msLevel = 1}.
#'
#' @param ... ignored.
#'
#' @return For \code{findChromPeaks}: if \code{return.type = "XCMSnExp"} an
#'     \code{\link{XCMSnExp}} object with the results of the peak detection.
#'     If \code{return.type = "list"} a list of length equal to the number of
#'     samples with matrices specifying the identified peaks.
#'     If \code{return.type = "xcmsSet"} an \code{\linkS4class{xcmsSet}} object
#'     with the results of the peak detection.
#'
#' @seealso \code{\link{XCMSnExp}} for the object containing the results of
#'     the peak detection.
#'
#' @rdname findChromPeaks-centWave
setMethod("findChromPeaks",
          signature(object = "OnDiskMSnExp", param = "CentWaveParam"),
          function(object, param, BPPARAM = bpparam(), return.type = "XCMSnExp",
                   msLevel = 1L, ...) {
              return.type <- match.arg(return.type, c("XCMSnExp", "list",
                                                      "xcmsSet"))
              startDate <- date()
              ## Restrict to MS X data.
              if (length(msLevel) > 1)
                  stop("Currently only peak detection in a single MS level is ",
                       "supported", call. = FALSE)
              ## Check if the data is centroided
              centroided <- all(centroided(object)[msLevel(object) %in% msLevel])
              if (is.na(centroided)) {
                  idx <- which(msLevel(object) %in% msLevel)
                  idx <- idx[ceiling(length(idx) / 3)]
                  suppressWarnings(
                      centroided <- isCentroided(object[[idx]])
                  )
              }
              if (is.na(centroided) || !centroided)
                  warning("Your data appears to be not centroided! CentWave",
                          " works best on data in centroid mode.")
              resList <- bplapply(.split_by_file2(object, msLevel. = msLevel),
                                  FUN = findChromPeaks_OnDiskMSnExp,
                                  method = "centWave",
                                  param = param, BPPARAM = BPPARAM)
              ## (3) collect the results.
              res <- .processResultList(resList,
                                        getProcHist = return.type == "xcmsSet",
                                        fnames = fileNames(object))

              if (return.type == "list")
                  return(res$peaks)
              object <- .peaks_to_result(res, object, startDate, param, msLevel)
              if (return.type == "xcmsSet")
                  as(object, "xcmsSet")
              else object
          })

## The matchedFilter peak detection method for OnDiskMSnExp:
#' @title Peak detection in the chromatographic time domain
#'
#' @description The \code{findChromPeaks,OnDiskMSnExp,MatchedFilterParam}
#'     method performs peak detection using the \emph{matchedFilter} algorithm
#'     on all samples from an \code{\link{OnDiskMSnExp}} object.
#'     \code{\link{OnDiskMSnExp}} objects encapsule all experiment
#'     specific data and load the spectra data (mz and intensity values) on the
#'     fly from the original files applying also all eventual data
#'     manipulations.
#'
#' @details Parallel processing (one process per sample) is supported and can
#'     be configured either by the \code{BPPARAM} parameter or by globally
#'     defining the parallel processing mode using the
#'     \code{\link{register}} method from the \code{BiocParallel}
#'     package.
#'
#' @param object For \code{findChromPeaks}: an
#'     \code{\link{OnDiskMSnExp}} object containing the MS- and all
#'     other experiment-relevant data.
#'
#'     For all other methods: a parameter object.
#'
#' @param param An \code{MatchedFilterParam} object containing all settings for
#'     the matchedFilter algorithm.
#'
#' @inheritParams findChromPeaks-centWave
#'
#' @return For \code{findChromPeaks}: if \code{return.type = "XCMSnExp"} an
#'     \code{\link{XCMSnExp}} object with the results of the peak detection.
#'     If \code{return.type = "list"} a list of length equal to the number of
#'     samples with matrices specifying the identified peaks.
#'     If \code{return.type = "xcmsSet"} an \code{\linkS4class{xcmsSet}} object
#'     with the results of the peak detection.
#'
#' @seealso \code{\link{XCMSnExp}} for the object containing the results of
#'     the chromatographic peak detection.
#'
#' @rdname findChromPeaks-matchedFilter
setMethod("findChromPeaks",
          signature(object = "OnDiskMSnExp", param = "MatchedFilterParam"),
          function(object, param, BPPARAM = bpparam(), return.type = "XCMSnExp",
                   msLevel = 1L, ...) {
              return.type <- match.arg(return.type, c("XCMSnExp", "list",
                                                      "xcmsSet"))
              startDate <- date()
              ## Restrict to MS X data.
              if (length(msLevel) > 1)
                  stop("Currently only peak detection in a single MS level is ",
                       "supported")
              resList <- bplapply(.split_by_file2(object, msLevel. = msLevel),
                                  FUN = findChromPeaks_OnDiskMSnExp,
                                  method = "matchedFilter",
                                  param = param,
                                  BPPARAM = BPPARAM)
              ## (3) collect the results.
              res <- .processResultList(resList,
                                        getProcHist = return.type == "xcmsSet",
                                        fnames = fileNames(object))
              if (return.type == "list")
                  return(res$peaks)
              object <- .peaks_to_result(res, object, startDate, param, msLevel)
              if (return.type == "xcmsSet")
                  as(object, "xcmsSet")
              else object
          })

#' Simple helper function to convert the peak finding results to an XCMSnExp
#' result object.
#'
#' @noRd
.peaks_to_result <- function(res, object, startDate, param, msLevel) {
    xph <- XProcessHistory(param = param, date. = startDate,
                           type. = .PROCSTEP.PEAK.DETECTION,
                           fileIndex = 1:length(fileNames(object)),
                           msLevel = msLevel)
    object <- as(object, "XCMSnExp")
    phist <- object@.processHistory
    ## if (hasAdjustedRtime(object) | hasFeatures(object))
    ##     object@msFeatureData <- new("MsFeatureData")
    pks <- do.call(rbind, res$peaks)
    if (length(pks) > 0) {
        chromPeaks(object) <- pks
        chromPeakData(object)$ms_level <- as.integer(msLevel)
        chromPeakData(object)$is_filled <- FALSE
    }
    object@.processHistory <- c(phist, list(xph))
    validObject(object)
    object
}

## massifquant
## The massifquant peak detection method for OnDiskMSnExp:
#' @title Chromatographic peak detection using the massifquant method
#'
#' @description The \code{findChromPeaks,OnDiskMSnExp,MassifquantParam}
#'     method performs chromatographic peak detection using the
#'     \emph{massifquant} algorithm on all samples from an
#'     \code{\link{OnDiskMSnExp}} object.
#'     \code{\link{OnDiskMSnExp}} objects encapsule all experiment
#'     specific data and load the spectra data (mz and intensity values) on the
#'     fly from the original files applying also all eventual data
#'     manipulations.
#'
#' @details Parallel processing (one process per sample) is supported and can
#'     be configured either by the \code{BPPARAM} parameter or by globally
#'     defining the parallel processing mode using the
#'     \code{\link{register}} method from the \code{BiocParallel}
#'     package.
#'
#' @param object For \code{findChromPeaks}: an
#'     \code{\link{OnDiskMSnExp}} object containing the MS- and all
#'     other experiment-relevant data.
#'
#'     For all other methods: a parameter object.
#'
#' @param param An \code{MassifquantParam} object containing all settings for
#'     the massifquant algorithm.
#'
#' @inheritParams findChromPeaks-centWave
#'
#' @return For \code{findChromPeaks}: if \code{return.type = "XCMSnExp"} an
#'     \code{\link{XCMSnExp}} object with the results of the peak detection.
#'     If \code{return.type = "list"} a list of length equal to the number of
#'     samples with matrices specifying the identified peaks.
#'     If \code{return.type = "xcmsSet"} an \code{\linkS4class{xcmsSet}} object
#'     with the results of the peak detection.
#'
#' @seealso \code{\link{XCMSnExp}} for the object containing the results of
#'     the peak detection.
#'
#' @rdname findChromPeaks-massifquant
setMethod("findChromPeaks",
          signature(object = "OnDiskMSnExp", param = "MassifquantParam"),
          function(object, param, BPPARAM = bpparam(), return.type = "XCMSnExp",
                   msLevel = 1L, ...) {
              return.type <- match.arg(return.type, c("XCMSnExp", "list",
                                                      "xcmsSet"))
              startDate <- date()
              ## Restrict to MS X data.
              if (length(msLevel) > 1)
                  stop("Currently only peak detection in a single MS level is ",
                       "supported")
              resList <- bplapply(.split_by_file2(object, msLevel. = msLevel),
                                  FUN = findChromPeaks_OnDiskMSnExp,
                                  method = "massifquant", param = param,
                                  BPPARAM = BPPARAM)
              ## (3) collect the results.
              res <- .processResultList(resList,
                                        getProcHist = return.type == "xcmsSet",
                                        fnames = fileNames(object))
              if (return.type == "list")
                  return(res$peaks)
              object <- .peaks_to_result(res, object, startDate, param, msLevel)
              if (return.type == "xcmsSet")
                  as(object, "xcmsSet")
              else object
          })


## MSW
## The MSW peak detection method for OnDiskMSnExp:
#' @title Single-spectrum non-chromatography MS data peak detection
#'
#' @description The \code{findChromPeaks,OnDiskMSnExp,MSWParam}
#'     method performs peak detection in single-spectrum non-chromatography MS
#'     data using functionality from the \code{MassSpecWavelet} package on all
#'     samples from an \code{\link{OnDiskMSnExp}} object.
#'     \code{\link{OnDiskMSnExp}} objects encapsule all experiment
#'     specific data and load the spectra data (mz and intensity values) on the
#'     fly from the original files applying also all eventual data
#'     manipulations.
#'
#' @details Parallel processing (one process per sample) is supported and can
#'     be configured either by the \code{BPPARAM} parameter or by globally
#'     defining the parallel processing mode using the
#'     \code{\link{register}} method from the \code{BiocParallel}
#'     package.
#'
#' @param object For \code{findChromPeaks}: an
#'     \code{\link{OnDiskMSnExp}} object containing the MS- and all
#'     other experiment-relevant data.
#'
#'     For all other methods: a parameter object.
#'
#' @param param An \code{MSWParam} object containing all settings for
#'     the algorithm.
#'
#' @inheritParams findChromPeaks-centWave
#'
#' @return For \code{findChromPeaks}: if \code{return.type = "XCMSnExp"} an
#'     \code{\link{XCMSnExp}} object with the results of the peak detection.
#'     If \code{return.type = "list"} a list of length equal to the number of
#'     samples with matrices specifying the identified peaks.
#'     If \code{return.type = "xcmsSet"} an \code{\linkS4class{xcmsSet}} object
#'     with the results of the detection.
#'
#' @seealso \code{\link{XCMSnExp}} for the object containing the results of
#'     the peak detection.
#'
#' @rdname findPeaks-MSW
setMethod("findChromPeaks",
          signature(object = "OnDiskMSnExp", param = "MSWParam"),
          function(object, param, BPPARAM = bpparam(), return.type = "XCMSnExp",
                   msLevel = 1L, ...) {
              return.type <- match.arg(return.type, c("XCMSnExp", "list",
                                                      "xcmsSet"))
              startDate <- date()
              ## Restrict to MS X data.
              if (length(msLevel) > 1)
                  stop("Currently only peak detection in a single MS level is ",
                       "supported")
              object_mslevel <- filterMsLevel(object, msLevel. = msLevel)
              if (length(object_mslevel) == 0)
                  stop("No MS level ", msLevel, " spectra present to perform ",
                       "peak detection")

              rts <- split(rtime(object_mslevel),
                           f = as.factor(fromFile(object_mslevel)))
              if (any(lengths(rts) > 1))
                  stop("The MSW method can only be applied to single spectrum,",
                       " non-chromatographic, files (i.e. with a single ",
                       "retention time).")
              resList <- bplapply(.split_by_file2(object_mslevel),
                                  FUN = findPeaks_MSW_OnDiskMSnExp,
                                  method = "MSW", param = param,
                                  BPPARAM = BPPARAM)
              ## (3) collect the results.
              res <- .processResultList(resList,
                                        getProcHist = return.type == "xcmsSet",
                                        fnames = fileNames(object_mslevel))
              if (return.type == "list")
                  return(res$peaks)
              object <- .peaks_to_result(res, object, startDate, param, msLevel)
              if (return.type == "xcmsSet")
                  as(object, "xcmsSet")
              else object
          })

## The centWave with predicted isotope peak detection method for OnDiskMSnExp:
#' @title Two-step centWave peak detection considering also isotopes
#'
#' @description The \code{findChromPeaks,OnDiskMSnExp,CentWavePredIsoParam}
#'     method performs a two-step centWave-based chromatographic peak detection
#'     on all samples from an \code{\link{OnDiskMSnExp}} object.
#'     \code{\link{OnDiskMSnExp}} objects encapsule all experiment
#'     specific data and load the spectra data (mz and intensity values) on the
#'     fly from the original files applying also all eventual data
#'     manipulations.
#'
#' @details Parallel processing (one process per sample) is supported and can
#'     be configured either by the \code{BPPARAM} parameter or by globally
#'     defining the parallel processing mode using the
#'     \code{\link{register}} method from the \code{BiocParallel}
#'     package.
#'
#' @param param An \code{CentWavePredIsoParam} object with the settings for the
#'     chromatographic peak detection algorithm.
#'
#' @inheritParams findChromPeaks-centWave
#'
#' @return For \code{findChromPeaks}: if \code{return.type = "XCMSnExp"} an
#'     \code{\link{XCMSnExp}} object with the results of the peak detection.
#'     If \code{return.type = "list"} a list of length equal to the number of
#'     samples with matrices specifying the identified peaks.
#'     If \code{return.type = "xcmsSet"} an \code{\linkS4class{xcmsSet}} object
#'     with the results of the peak detection.
#'
#' @seealso \code{\link{XCMSnExp}} for the object containing the results of
#'     the peak detection.
#'
#' @rdname findChromPeaks-centWaveWithPredIsoROIs
setMethod("findChromPeaks",
          signature(object = "OnDiskMSnExp", param = "CentWavePredIsoParam"),
          function(object, param, BPPARAM = bpparam(), return.type = "XCMSnExp",
                   msLevel = 1L, ...) {
              return.type <- match.arg(return.type, c("XCMSnExp", "list",
                                                      "xcmsSet"))
              startDate <- date()
              ## Restrict to MS X data.
              if (length(msLevel) > 1)
                  stop("Currently only peak detection in a single MS level is ",
                       "supported")
              ## Check if the data is centroided
              centroided <- all(centroided(object)[msLevel(object) %in% msLevel])
              if (is.na(centroided)) {
                  idx <- which(msLevel(object) %in% msLevel)
                  idx <- idx[ceiling(length(idx) / 3)]
                  suppressWarnings(
                      centroided <- isCentroided(object[[idx]])
                  )
              }
              if (is.na(centroided) || !centroided)
                  warning("Your data appears to be not centroided! CentWave",
                          " works best on data in centroid mode.")
              resList <- bplapply(.split_by_file2(object, msLevel. = msLevel),
                                  FUN = findChromPeaks_OnDiskMSnExp,
                                  method = "centWaveWithPredIsoROIs",
                                  param = param, BPPARAM = BPPARAM)
              ## (3) collect the results.
              res <- .processResultList(resList,
                                        getProcHist = return.type == "xcmsSet",
                                        fnames = fileNames(object))

              if (return.type == "list")
                  return(res$peaks)
              object <- .peaks_to_result(res, object, startDate, param, msLevel)
              if (return.type == "xcmsSet")
                  as(object, "xcmsSet")
              else object
          })

## profMat method for XCMSnExp/OnDiskMSnExp.
#' @description \code{profMat}: creates a \emph{profile matrix}, which
#'     is a n x m matrix, n (rows) representing equally spaced m/z values (bins)
#'     and m (columns) the retention time of the corresponding scans. Each cell
#'     contains the maximum intensity measured for the specific scan and m/z
#'     values. See \code{\link{profMat}} for more details and description of
#'     the various binning methods.
#'
#' @param ... Additional parameters.
#'
#' @return For \code{profMat}: a \code{list} with a the profile matrix
#'     \code{matrix} (or matrices if \code{fileIndex} was not specified or if
#'     \code{length(fileIndex) > 1}). See \code{\link{profile-matrix}} for
#'     general help and information about the profile matrix.
#'
#' @inheritParams profMat-xcmsSet
#'
#' @rdname XCMSnExp-class
setMethod("profMat", "OnDiskMSnExp", function(object,
                                              method = "bin",
                                              step = 0.1,
                                              baselevel = NULL,
                                              basespace = NULL,
                                              mzrange. = NULL,
                                              fileIndex,
                                              ...) {
    ## Subset the object by fileIndex.
    if (!missing(fileIndex)) {
        if (!is.numeric(fileIndex))
            stop("'fileIndex' has to be an integer.")
        if (!all(fileIndex %in% seq_along(fileNames(object))))
            stop("'fileIndex' has to be an integer between 1 and ",
                 length(fileNames(object)), "!")
        object <- filterFile(object, fileIndex)
    }
    ## Split it by file and bplapply over it to generate the profile matrix.
    theF <- factor(seq_along(fileNames(object)))
    theDots <- list(...)
    if (any(names(theDots) == "returnBreaks"))
        returnBreaks <- theDots$returnBreaks
    else
        returnBreaks <- FALSE
    res <- bplapply(splitByFile(object, f = theF), function(z, bmethod, bstep,
                                                            bbaselevel,
                                                            bbasespace,
                                                            bmzrange.,
                                                            breturnBreaks) {
        require(xcms, quietly = TRUE)
        sps <- spectra(z, BPPARAM = SerialParam())
        mzs <- lapply(sps, mz)
        ## Fix for issue #301: got spectra with m/z being NA.
        if (any(is.na(unlist(mzs, use.names = FALSE)))) {
            sps <- lapply(sps, clean, all = TRUE)
            mzs <- lapply(sps, mz)
        }
        ## Fix for issue #312: remove empty spectra, that we are however adding
        ## later so that the ncol(profMat) == length(rtime(object))
        pk_count <- lengths(mzs)
        empty_spectra <- which(pk_count == 0)
        if (length(empty_spectra)) {
            mzs <- mzs[-empty_spectra]
            sps <- sps[-empty_spectra]
        }
        vps <- lengths(mzs, use.names = FALSE)
        res <- .createProfileMatrix(mz = unlist(mzs, use.names = FALSE),
                                    int = unlist(lapply(sps, intensity),
                                                 use.names = FALSE),
                                    valsPerSpect = vps,
                                    method = bmethod,
                                    step = bstep,
                                    baselevel = bbaselevel,
                                    basespace = bbasespace,
                                    mzrange. = bmzrange.,
                                    returnBreaks = breturnBreaks)
        if (length(empty_spectra))
            if (returnBreaks)
                res$profMat <- .insertColumn(res$profMat, empty_spectra, 0)
            else
                res <- .insertColumn(res, empty_spectra, 0)
        res
    }, bmethod = method, bstep = step, bbaselevel = baselevel,
    bbasespace = basespace, bmzrange. = mzrange., breturnBreaks = returnBreaks)
    res
})

#' @rdname adjustRtime
setMethod("adjustRtime",
          signature(object = "OnDiskMSnExp", param = "ObiwarpParam"),
          function(object, param, msLevel = 1L) {
              ## Filter for MS level, perform adjustment and if the object
              ## contains spectra from other MS levels too, adjust all raw
              ## rts based on the difference between adjusted and raw rts.
              object_sub <- filterMsLevel(object, msLevel = msLevel)
              if (length(object_sub) == 0)
                  stop("No spectra of MS level ", msLevel, " present")
              res <- .obiwarp(object_sub, param = param)
              ## Adjust the retention time for spectra of all MS levels, if
              ## if there are some other than msLevel (issue #214).
              if (length(unique(msLevel(object))) !=
                  length(unique(msLevel(object_sub)))) {
                  message("Apply retention time correction performed on MS",
                          msLevel, " to spectra from all MS levels")
                  ## I need raw and adjusted rt for the adjusted spectra
                  ## and the raw rt of all.
                  rtime_all <- split(rtime(object), fromFile(object))
                  rtime_sub <- split(rtime(object_sub), fromFile(object_sub))
                  ## For loop is faster than lapply. No sense to do parallel
                  for (i in 1:length(rtime_all)) {
                      n_vals <- length(rtime_sub[[i]])
                      idx_below <- which(rtime_all[[i]] < rtime_sub[[i]][1])
                      if (length(idx_below))
                          vals_below <- rtime_all[[i]][idx_below]
                      idx_above <- which(rtime_all[[i]] >
                                         rtime_sub[[i]][n_vals])
                      if (length(idx_above))
                          vals_above <- rtime_all[[i]][idx_above]
                      ## Adjust the retention time. Note: this should be
                      ## OK even if values are not sorted.
                      adj_fun <- approxfun(x = rtime_sub[[i]], y = res[[i]])
                      rtime_all[[i]] <- adj_fun(rtime_all[[i]])
                      ## Adjust rtime < smallest adjusted rtime.
                      if (length(idx_below)) {
                          rtime_all[[i]][idx_below] <- vals_below +
                              res[[i]][1] - rtime_sub[[i]][1]
                      }
                      ## Adjust rtime > largest adjusted rtime
                      if (length(idx_above)) {
                          rtime_all[[i]][idx_above] <- vals_above +
                              res[[i]][n_vals] - rtime_sub[[i]][n_vals]
                      }
                  }
                  res <- rtime_all
              }
              res <- unlist(res, use.names = FALSE)
              sNames <- unlist(split(featureNames(object),
                                     as.factor(fromFile(object))),
                               use.names = FALSE)
              names(res) <- sNames
              res <- res[featureNames(object)]
              res
          })

#' @rdname extractMsData-method
setMethod("extractMsData", signature(object = "OnDiskMSnExp"),
          function(object, rt, mz, msLevel = 1L) {
              .Deprecated(msg = paste0("Use of 'extractMsData' is deprecated.",
                                       " Please use 'as(x, \"data.frame\")'"))
              .extractMsData(object, rt = rt, mz = mz, msLevel = msLevel)
          })

setMethod("hasAdjustedRtime", signature(object = "OnDiskMSnExp"),
          function(object)
              FALSE
          )

#' @title Extract isolation window target m/z definition
#'
#' @aliases isolationWindowTargetMz
#'
#' @description
#'
#' `isolationWindowTargetMz` extracts the isolation window target m/z definition
#' for each spectrum in `object`.
#'
#' @param object [OnDiskMSnExp-class] object.
#'
#' @return a `numeric` of length equal to the number of spectra in `object` with
#'     the isolation window target m/z or `NA` if not specified/available.
#'
#' @author Johannes Rainer
#'
#' @md
setMethod("isolationWindowTargetMz", "OnDiskMSnExp", function(object) {
    if ("isolationWindowTargetMZ" %in% colnames(.fdata(object)))
        return(.fdata(object)$isolationWindowTargetMZ)
    rep(NA_real_, length(object))
})

#' @rdname findChromPeaksIsolationWindow
setMethod(
    "findChromPeaksIsolationWindow", "OnDiskMSnExp",
    function(object, param, msLevel = 2L,
             isolationWindow = isolationWindowTargetMz(object), ...) {
        startDate <- date()
        if (!is.factor(isolationWindow))
            isolationWindow <- factor(isolationWindow)
        if (length(isolationWindow) != length(object))
            stop("length of 'isolationWindow' has to match length of 'object'")
        if (all(is.na(isolationWindow)))
            stop("all isolation windows in 'isolationWindow' are NA")
        fData(object)$isolationWindow <- isolationWindow
        obj_sub <- selectFeatureData(as(object, "OnDiskMSnExp"),
                                     fcol = c(MSnbase:::.MSnExpReqFvarLabels,
                                              "centroided",
                                              "isolationWindow",
                                              "isolationWindowTargetMZ",
                                              "isolationWindowLowerOffset",
                                              "isolationWindowUpperOffset"))
        if (inherits(object, "XCMSnExp"))
            fData(obj_sub)$retentionTime <- rtime(object)
        res <- lapply(split(obj_sub, f = isolationWindow),
                      FUN = findChromPeaks, param = param, msLevel = msLevel)
        if (!inherits(object, "XCMSnExp"))
            object <- as(object, "XCMSnExp")
        msf <- new("MsFeatureData")
        msf@.xData <- .copy_env(object@msFeatureData)
        msf <- .swath_collect_chrom_peaks(res, msf, fileNames(object))
        lockEnvironment(msf, bindings = TRUE)
        object@msFeatureData <- msf
        xph <- XProcessHistory(param = param, date. = startDate,
                               type. = .PROCSTEP.PEAK.DETECTION,
                               fileIndex = 1:length(fileNames(object)),
                               msLevel = msLevel)
        object@.processHistory <- c(processHistory(object), list(xph))
        validObject(object)
        object
    })

#' @title Estimate precursor intensity for MS level 2 spectra
#'
#' @description
#'
#' `estimatePrecursorIntensity()` determines the precursor intensity for a MS 2
#' spectrum based on the intensity of the respective signal from the
#' neighboring MS 1 spectra (i.e. based on the peak with the m/z matching the
#' precursor m/z of the MS 2 spectrum). Based on parameter `method` either the
#' intensity of the peak from the previous MS 1 scan is used
#' (`method = "previous"`) or an interpolation between the intensity from the
#' previous and subsequent MS1 scan is used (`method = "interpolation"`, which
#' considers also the retention times of the two MS1 scans and the retention
#' time of the MS2 spectrum).
#'
#' @param object `MsExperiment`, `XcmsExperiment`, `OnDiskMSnExp` or
#'     `XCMSnExp` object.
#'
#' @param ppm `numeric(1)` defining the maximal acceptable difference (in ppm)
#'     of the precursor m/z and the m/z of the corresponding peak in the MS 1
#'     scan.
#'
#' @param tolerance `numeric(1)` with the maximal allowed difference of m/z
#'     values between the precursor m/z of a spectrum and the m/z of the
#'     respective ion on the MS1 scan.
#'
#' @param method `character(1)` defining the method how the precursor intensity
#'     should be determined (see description above for details). Defaults to
#'     `method = "previous"`.
#'
#' @param BPPARAM parallel processing setup. See [bpparam()] for details.
#'
#' @return `numeric` with length equal to the number of spectra in `x`. `NA` is
#'     returned for MS 1 spectra or if no matching peak in a MS 1 scan can be
#'     found for an MS 2 spectrum
#'
#' @author Johannes Rainer with feedback and suggestions from Corey Broeckling
#'
#' @md
#'
#' @rdname estimatePrecursorIntensity
setMethod(
    "estimatePrecursorIntensity", "OnDiskMSnExp",
    function(object, ppm = 10, tolerance = 0,
             method = c("previous", "interpolation"),
             BPPARAM = bpparam()) {
        method <- match.arg(method)
        unlist(bplapply(.split_by_file2(object, subsetFeatureData = FALSE),
                        .estimate_prec_intensity, ppm = ppm,
                        tolerance = tolerance, method = method,
                        BPPARAM = BPPARAM), use.names = FALSE)
    })
