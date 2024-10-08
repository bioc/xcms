library(MsExperiment)
mse <- MsExperiment()
fls <- normalizePath(faahko_3_files)
df <- data.frame(mzML_file = basename(fls),
                 dataOrigin = fls,
                 sample = c("ko15", "ko16", "ko18"))

spectra(mse) <- Spectra::Spectra(fls)
sampleData(mse) <- DataFrame(df)
## Link samples to spectra.
mse <- linkSampleData(mse, with = "sampleData.dataOrigin = spectra.dataOrigin")

test_that(".param_to_fun works", {
    expect_equal(.param_to_fun(CentWaveParam()), "do_findChromPeaks_centWave")
    expect_error(.param_to_fun(DataFrame()), "No peak detection")
})

test_that(".mse_sample_apply works", {
    dummy <- MsExperiment()
    spectra(dummy) <- spectra(mse)

    res <- .mse_sample_apply(dummy, length, BPPARAM = SerialParam())
    expect_true(length(res) == 0)

    res <- .mse_sample_apply(mse, length, BPPARAM = SerialParam())
    expect_equal(res, list(`1` = 1L, `2` = 1L, `3` = 1L))

    res <- .mse_sample_apply(mse, function(z, msLevel) {
        length(filterMsLevel(spectra(z), msLevel))
    }, msLevel = 1L, BPPARAM = SerialParam())
    expect_equal(unlist(res, use.names = FALSE),
                 as.integer(table(fromFile(od_x))))
    res <- .mse_sample_apply(mse, function(z, msLevel) {
        length(filterMsLevel(spectra(z), msLevel))
    }, msLevel = 2L, BPPARAM = SerialParam())
    expect_equal(unlist(res), c(`1` = 0L, `2` = 0L, `3` = 0L))
})

test_that(".mse_sample_spectra_apply works", {
    dummy <- MsExperiment()
    expect_error(.mse_sample_spectra_apply(dummy), "No spectra")

    spectra(dummy) <- spectra(mse)
    expect_error(.mse_sample_spectra_apply(dummy, length), "No link")

    res <- .mse_sample_spectra_apply(mse, length, BPPARAM = SerialParam())
    expect_equal(res, list(`1` = 1278, `2` = 1278, `3` = 1278))

    res <- .mse_sample_spectra_apply(mse, function(z, msLevel) {
        length(filterMsLevel(z, msLevel))
    }, msLevel = 1L, BPPARAM = SerialParam())
    expect_equal(unlist(res, use.names = FALSE),
                 as.integer(table(fromFile(od_x))))
    res <- .mse_sample_spectra_apply(mse, function(z, msLevel) {
        length(filterMsLevel(z, msLevel))
    }, msLevel = 2L, BPPARAM = SerialParam())
    expect_equal(unlist(res), c(`1` = 0L, `2` = 0L, `3` = 0L))
})

test_that(".mse_find_chrom_peaks_sample works", {
    p <- CentWaveParam(noise = 10000, snthresh = 40, prefilter = c(3, 10000))
    res <- .mse_find_chrom_peaks_sample(spectra(mse[2L]), param = p)
    tmp <- chromPeaks(faahko_xod)
    tmp <- tmp[tmp[, "sample"] == 2, colnames(tmp) != "sample"]
    rownames(tmp) <- NULL
    expect_equal(res, tmp)

    res <- .mse_find_chrom_peaks_sample(spectra(mse[1L]), param = p,
                                        msLevel = 2L)
    expect_true(is.null(res))
})

test_that(".mse_find_chrom_peaks works", {
    p <- CentWaveParam(noise = 10000, snthresh = 40, prefilter = c(3, 10000))
    res <- .mse_find_chrom_peaks(mse, param = p)
    tmp <- chromPeaks(faahko_xod)
    rownames(tmp) <- NULL
    expect_equal(tmp, res)

    res <- .mse_find_chrom_peaks(mse, param = p, msLevel = 2L)
    expect_true(nrow(res) == 0)
    expect_equal(colnames(res), colnames(.empty_chrom_peaks()))
})

test_that(".mse_spectrapply_chunks works", {
    expect_error(.mse_spectrapply_chunks(MsExperiment), "spectra")

    myident <- function(z, ...) {z}
    res <- .mse_spectrapply_chunks(mse, FUN = myident)
    expect_true(is.list(res))
    expect_true(length(res) == 3)
    expect_equal(rtime(res[[1L]]), rtime(spectra(mse[1L])))
    expect_equal(rtime(res[[2L]]), rtime(spectra(mse[2L])))
    expect_equal(rtime(res[[3L]]), rtime(spectra(mse[3L])))

    res <- .mse_spectrapply_chunks(mse, FUN = myident, chunkSize = 2)
    res2 <- .mse_spectrapply_chunks(mse, FUN = myident, chunkSize = 2,
                                    progressbar = FALSE)
    expect_equal(res, res2)
    expect_true(is.list(res))
    expect_true(length(res) == 2)
    expect_equal(rtime(res[[1L]]), c(rtime(spectra(mse[1L])),
                                     rtime(spectra(mse[2L]))))
    expect_equal(rtime(res[[2L]]), rtime(spectra(mse[3L])))
})

test_that(".mse_find_chrom_peaks_chunks works", {
    p <- CentWaveParam(noise = 10000, snthresh = 40, prefilter = c(3, 10000))

    res <- .mse_find_chrom_peaks_chunks(mse, param = p)
    tmp <- chromPeaks(faahko_xod)
    rownames(tmp) <- NULL
    expect_equal(tmp, res)

    res <- .mse_find_chrom_peaks_chunks(mse, param = p, msLevel = 2L)
    expect_true(nrow(res) == 0)
    expect_equal(res, .empty_chrom_peaks())
})


test_that(".mse_find_chrom_peaks_chunk works", {
    p <- CentWaveParam(noise = 10000, snthresh = 40, prefilter = c(3, 10000))
    sps <- spectra(mse[1:2])[mse[1:2]@sampleDataLinks[["spectra"]][, 2L]]
    sps$.SAMPLE_IDX <- mse[1:2]@sampleDataLinks[["spectra"]][, 1L]

    res <- .mse_find_chrom_peaks_chunk(sps, param = p)
    expect_true(is.list(res))
    expect_true(length(res) == 2)

    cp <- chromPeaks(faahko_xod)
    f <- cp[, "sample"]
    rownames(cp) <- NULL
    cpl <- split.data.frame(cp[, colnames(cp) != "sample"], f)
    expect_equal(cpl[[1L]], res[[1L]])
    expect_equal(cpl[[2L]], res[[2L]])

    res <- .mse_find_chrom_peaks_chunk(sps, param = p, msLevel = 2L)
    expect_true(is.list(res))
    expect_true(length(res) == 2)
    expect_true(is.null(res[[1L]]))
    expect_true(is.null(res[[2L]]))
})

test_that(".mse_check_spectra_sample_mapping works", {
    expect_true(length(.mse_check_spectra_sample_mapping(mse)) == 0)

    tmp <- mse
    tmp@sampleDataLinks[["spectra"]] <-
        mse@sampleDataLinks[["spectra"]][1:100, ]
    expect_error(.mse_check_spectra_sample_mapping(tmp), "assigned to a sample")

    tmp@sampleDataLinks[["spectra"]] <- mse@sampleDataLinks[["spectra"]]
    tmp@sampleDataLinks[["spectra"]][3, ] <- c(2L, 2L)
    expect_error(.mse_check_spectra_sample_mapping(tmp), "single sample")
})

test_that(".mse_profmat_chunk works", {
    tmp <- mse[1]
    ref <- profMat(faahko_od, fileIndex = 1)

    sps <- spectra(tmp)
    sps$.SAMPLE_IDX <- 1L
    res <- .mse_profmat_chunk(sps)
    expect_equal(unname(res), ref)

    ref <- profMat(faahko_od, fileIndex = 1:2, step = 2, returnBreaks = TRUE)
    tmp <- mse[1:2]
    sps <- spectra(tmp)
    sps$.SAMPLE_IDX <- tmp@sampleDataLinks[["spectra"]][, 1L]
    res <- .mse_profmat_chunk(sps, step = 2, returnBreaks = TRUE)
    expect_equal(unname(res), ref)
    expect_true(all(names(res[[1L]]) == c("profMat", "breaks")))

    res <- .mse_profmat_chunk(sps, step = 2, msLevel = 2)
    expect_equal(length(res), 2)
    expect_true(nrow(res[[1L]]) == 0)
    expect_true(nrow(res[[2L]]) == 0)
})

test_that(".mse_profmat_chunks works", {
    expect_error(.mse_profmat_chunks(mse, fileIndex = 5), "bounds")
    expect_error(.mse_profmat_chunks(mse, fileIndex = 1:5), "bounds")

    ref <- profMat(faahko_od, fileIndex = 3)
    res <- .mse_profmat_chunks(mse, fileIndex = 3)
    expect_equal(ref, res)

    ref <- profMat(faahko_od, returnBreaks = TRUE, step = 4)
    res <- .mse_profmat_chunks(mse, chunkSize = 2L, step = 4,
                               returnBreaks = TRUE)
    expect_equal(res, ref)
    expect_equal(names(res[[1L]]), c("profMat", "breaks"))

    res <- .mse_profmat_chunks(mse, chunkSize = 3L, msLevel = 2L)
    expect_true(length(res) == 3)

    ## Testing the method.
    res <- profMat(mse, chunkSize = 2L, step = 4, returnBreaks = TRUE)
    expect_equal(res, ref)
})

test_that(".obiwarp_spectra works", {
    p <- ObiwarpParam(binSize = 3.4, centerSample = 1L)
    ref <- split(adjustRtime(faahko_od, param = p), fromFile(faahko_od))

    a <- spectra(mse[1L])
    b <- spectra(mse[2L])
    res <- .obiwarp_spectra(b, a, param = p)
    expect_equal(res, unname(ref[[2L]]))
    res <- .obiwarp_spectra(spectra(mse[3L]), a, param = p)
    expect_equal(res, unname(ref[[3L]]))

    ## Test with different MS levels.
    res_sub <- .obiwarp_spectra(b[-seq(1, length(b), by = 3)],
                                   a[-seq(1, length(a), by = 3)],
                                   param = p)
    a$msLevel[seq(1, length(a), by = 3)] <- 2L
    b$msLevel[seq(1, length(b), by = 3)] <- 2L
    res2 <- .obiwarp_spectra(b, a, param = p)
    expect_equal(length(res2), length(b))
    expect_equal(res_sub, res2[-seq(1, length(b), by = 3)])
    expect_true(cor(res, res2) > 0.999)
})

test_that(".mse_obiwarp_chunks works", {
    p <- ObiwarpParam(binSize = 50, centerSample = 1L)
    ref <- split(adjustRtime(faahko_od, param = p), fromFile(faahko_od))

    expect_error(.mse_obiwarp_chunks(mse, ObiwarpParam(centerSample = 6)),
                 "integer between 1 and 3")

    res <- .mse_obiwarp_chunks(mse, p)
    expect_true(is.list(res))
    expect_equal(length(res), length(mse))
    expect_equal(unname(ref[[1L]]), res[[1L]])
    expect_equal(unname(ref[[2L]]), res[[2L]])
    expect_equal(unname(ref[[3L]]), res[[3L]])

    ## Subset alignment...
    p <- ObiwarpParam(binSize = 30, centerSample = 1L, subset = c(1, 3))
    ref <- split(adjustRtime(faahko_od, param = p), fromFile(faahko_od))

    res <- .mse_obiwarp_chunks(mse, p, chunkSize = 2L)
    expect_equal(unname(ref[[1L]]), res[[1L]])
    expect_equal(unname(ref[[2L]]), res[[2L]])
    expect_equal(unname(ref[[3L]]), res[[3L]])

    expect_error(.mse_obiwarp_chunks(mse, p, msLevel = 2), "MS level")
})

test_that(".mse_chromatogram works", {
    rtr <- rbind(c(2600, 2630), c(3500, 3600))
    mzr <- rbind(c(250, 252), c(400, 410))

    res <- .mse_chromatogram(mse, rt = rtr, mz = mzr, msLevel = 1L)
    expect_s4_class(res, "MChromatograms")
    expect_equal(ncol(res), length(mse))
    expect_equal(nrow(res), 2)
    expect_true(validObject(res))

    ref <- chromatogram(faahko_od, mz = mzr, rt = rtr)
    expect_equal(unname(intensity(ref[1, 2])), intensity(res[1, 2]))
    expect_equal(unname(intensity(ref[2, 3])), intensity(res[2, 3]))

    ## aggregationFun passed correctly
    res_2 <- .mse_chromatogram(mse, rt = rtr, mz = mzr, msLevel = 1L,
                               aggregationFun = "max")
    expect_true(all(intensity(res[1, 1]) > intensity(res_2[1, 1])))
    expect_true(all(intensity(res[2, 2]) > intensity(res_2[2, 2])))

    ## MS Level 2
    res <- .mse_chromatogram(mse, rt = rtr, mz = mzr, msLevel = 2L)
    expect_s4_class(res, "MChromatograms")
    expect_equal(ncol(res), length(mse))
    expect_equal(nrow(res), 2)
    expect_true(validObject(res))
    expect_equal(intensity(res[1, 2]), numeric())

    ## rt, mz out of range
    rtr <- rbind(c(20, 30), c(34, 45))
    res <- .mse_chromatogram(mse, rt = rtr, mz = mzr, msLevel = 1L)
    expect_s4_class(res, "MChromatograms")
    expect_equal(ncol(res), length(mse))
    expect_equal(nrow(res), 2)
    expect_true(validObject(res))
    expect_equal(intensity(res[1, 2]), numeric())

    rtr <- rbind(c(20, 30), c(3500, 3600))
    res <- .mse_chromatogram(mse, rt = rtr, mz = mzr, msLevel = 1L)
    expect_s4_class(res, "MChromatograms")
    expect_equal(ncol(res), length(mse))
    expect_equal(nrow(res), 2)
    expect_true(validObject(res))
    expect_equal(intensity(res[1, 1]), numeric())
    expect_equal(intensity(res[1, 2]), numeric())
    expect_equal(intensity(res[1, 3]), numeric())
    expect_equal(unname(intensity(res[2, 1])), unname(intensity(ref[2, 1])))
    expect_equal(unname(intensity(res[2, 2])), unname(intensity(ref[2, 2])))
    expect_equal(unname(intensity(res[2, 3])), unname(intensity(ref[2, 3])))

    ## MsExperiment with non-overlapping rt ranges: check if results are
    ## correct.
    micro_mse <- MsExperiment()
    micro_fls <- normalizePath(microtofq_fs)
    df <- data.frame(mzML_file = basename(micro_fls),
                 dataOrigin = micro_fls,
                 sample = c("MM14", "MM8"))

    spectra(micro_mse) <- Spectra::Spectra(micro_fls)
    sampleData(micro_mse) <- DataFrame(df)
    ## Link samples to spectra.
    micro_mse <- linkSampleData(
        micro_mse, with = "sampleData.dataOrigin = spectra.dataOrigin")
    ## sample 1: rt 270-307, mz 94 1004
    ## sample 2: rt 0.4-66, mz 95 1005
    rtr <- rbind(c(13, 20), c(290, 301))
    mzr <- rbind(c(100, 200), c(100, 200))
    res <- .mse_chromatogram(micro_mse, rt = rtr, mz = mzr, msLevel = 1L)
    expect_s4_class(res, "MChromatograms")
    expect_equal(ncol(res), 2L)
    expect_equal(nrow(res), 2L)
    expect_true(validObject(res))
    expect_equal(intensity(res[1, 1]), numeric())
    expect_equal(intensity(res[2, 2]), numeric())
    ref <- chromatogram(microtofq_od, mz = mzr, rt = rtr)
    expect_equal(unname(intensity(res[1, 2])), unname(intensity(ref[1, 2])))
    expect_equal(unname(intensity(res[2, 1])), unname(intensity(ref[2, 1])))

    ## MS2 chromatogram with isolationWindow.
    ## Fails to extract chromatograms because DDA will not support that
    ## properly.
    fl <- system.file("TripleTOF-SWATH", "PestMix1_DDA.mzML",
                      package = "msdata")
    mse_dda <- readMsExperiment(fl)
    mzr <- rbind(c(100, 110),
                 c(500, 510))
    rtr <- rbind(c(200, 220),
                 c(500, 520))
    res <- .mse_chromatogram(mse_dda, rt = rtr, mz = mzr, msLevel = 1L)
    expect_true(validObject(res))
    expect_true(all(intensity(res[[1L]]) > 0))
    expect_true(all(intensity(res[[2L]]) > 0, na.rm = TRUE))
    res <- .mse_chromatogram(mse_dda, rt = rtr, mz = mzr, msLevel = 2L)
    expect_true(validObject(res))
    expect_equal(msLevel(res[[1L]]), 2L)
    expect_true(length(intensity(res[[1L]])) > 0)
    expect_equal(msLevel(res[[2L]]), 2L)
    expect_true(length(intensity(res[[2L]])) > 0)

    ## Set isolationWindowTargetMz.
    isolationWindowTargetMz(spectra(mse_dda)) <- as.numeric(
        as.integer(isolationWindowTargetMz(spectra(mse_dda))))
    mzr <- rbind(c(55, 57),
                 c(81, 83))
    rtr <- rbind(c(10, 700),
                 c(10, 700))
    res <- .mse_chromatogram(mse_dda, rt = rtr, mz = mzr, msLevel = 2L)
    res2 <- .mse_chromatogram(mse_dda, rt = rtr, mz = mzr, msLevel = 2L,
                                    isolationWindow = c(56, 40))
    expect_true(all(intensity(res2[[1L]]) > 0))
    expect_true(length(intensity(res2[[2L]])) == 0)
    expect_true(length(rtime(res[[1L]])) > length(rtime(res2[[1L]])))
    res2 <- .mse_chromatogram(mse_dda, rt = rtr, mz = mzr, msLevel = 2L,
                                     isolationWindow = c(56, 82))
    expect_true(all(intensity(res2[[1L]]) > 0))
    expect_true(length(intensity(res[[1L]])) > length(intensity(res2[[1L]])))
    expect_true(all(intensity(res[[2L]]) > 0, na.rm = TRUE))

    ## Can extract chromatograms if providing the correct isolationWindow.
    fl <- system.file("TripleTOF-SWATH", "PestMix1_SWATH.mzML",
                      package = "msdata")
    mse_dia <- readMsExperiment(fl)
    mzr <- rbind(c(100, 110),
                 c(500, 510))
    res <- .mse_chromatogram(mse_dia, mz = mzr, rt = rtr, msLevel = 1L)
    expect_equal(msLevel(res[[1L]]), 1L)
    expect_equal(msLevel(res[[2L]]), 1L)
    expect_true(length(intensity(res[[1L]])) > 0)
    expect_true(length(intensity(res[[2L]])) > 0)

    mzr <- rbind(c(40, 200),
                 c(40, 200))
    res <- .mse_chromatogram(mse_dia, mz = mzr, rt = rtr, msLevel = 2L,
                             isolationWindow = c(163.75, 367.35))
    expect_equal(msLevel(res[[1L]]), 2L)
    expect_equal(msLevel(res[[2L]]), 2L)
    expect_true(all(intensity(res[[1L]]) > 0))
    expect_true(all(intensity(res[[2L]]) > 0))
})

test_that(".mse_split_spectra_variable works", {
    ## MS level - results should be the same.
    res <- .mse_split_spectra_variable(mse, msLevel(spectra(mse)))
    expect_true(length(res) == 1L)
    expect_equal(res[[1L]]@sampleDataLinks, mse@sampleDataLinks)
    expect_equal(rtime(spectra(res[[1L]])), rtime(spectra(mse)))
    expect_equal(spectraVariables(spectra(res[[1L]])),
                 spectraVariables(spectra(mse)))

    ## create custom spectra variable.
    spv <- rep("A", length(spectra(mse)))
    spv[rtime(spectra(mse)) < 4000] <- "B"
    res <- .mse_split_spectra_variable(mse, spv)
    expect_true(length(res) == 2)
    expect_true(all(rtime(spectra(res[[1L]])) > 4000))
    expect_true(all(rtime(spectra(res[[2L]])) < 4000))
    a <- filterRt(spectra(mse[2]), c(0, 4000))
    expect_equal(rtime(a), rtime(spectra(res[[2L]][2])))
    a <- filterRt(spectra(mse[3]), c(4000, 10000))
    expect_equal(rtime(a), rtime(spectra(res[[1L]][3])))

    ## custom spectra variable with NAs in between.
    spv[rtime(spectra(mse)) > 3500 & rtime(spectra(mse)) < 4000] <- NA
    res <- .mse_split_spectra_variable(mse, spv)
    expect_true(length(res) == 2)
    expect_true(all(rtime(spectra(res[[1L]])) > 4000))
    expect_true(all(rtime(spectra(res[[2L]])) < 4000))
    a <- filterRt(spectra(mse[2]), c(0, 3500))
    expect_equal(rtime(a), rtime(spectra(res[[2L]][2])))
    a <- filterRt(spectra(mse[3]), c(4000, 10000))
    expect_equal(rtime(a), rtime(spectra(res[[1L]][3])))
})

test_that(".update_sample_data_links_spectra works", {
    tmp <- mse
    tmp@spectra$._SPECTRA_IDX <- seq_along(tmp@spectra)
    tmp@spectra <- tmp@spectra[c(5, 14, 3800, 2, 200)]
    res <- .update_sample_data_links_spectra(tmp)
    res@sampleDataLinks[["spectra"]]
    expect_equal(res@spectra$scanIndex, c(5, 14, 1244, 2, 200))
    expect_equal(res@sampleData, tmp@sampleData)

    ## !Order of spectra index in sampleDataLinks is NOT ordered
    expect_equal(res@sampleDataLinks[["spectra"]][, 2L], c(4, 1, 2, 5, 3))
    expect_true(length(spectra(res[1L])) == 4)
    expect_true(length(spectra(res[2L])) == 0)
    expect_true(length(spectra(res[3L])) == 1)
})
