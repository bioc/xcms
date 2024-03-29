% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/do_findChromPeaks-functions.R
\name{do_findChromPeaks_massifquant}
\alias{do_findChromPeaks_massifquant}
\title{Core API function for massifquant peak detection}
\usage{
do_findChromPeaks_massifquant(
  mz,
  int,
  scantime,
  valsPerSpect,
  ppm = 10,
  peakwidth = c(20, 50),
  snthresh = 10,
  prefilter = c(3, 100),
  mzCenterFun = "wMean",
  integrate = 1,
  mzdiff = -0.001,
  fitgauss = FALSE,
  noise = 0,
  verboseColumns = FALSE,
  criticalValue = 1.125,
  consecMissedLimit = 2,
  unions = 1,
  checkBack = 0,
  withWave = FALSE
)
}
\arguments{
\item{mz}{Numeric vector with the individual m/z values from all scans/
spectra of one file/sample.}

\item{int}{Numeric vector with the individual intensity values from all
scans/spectra of one file/sample.}

\item{scantime}{Numeric vector of length equal to the number of
spectra/scans of the data representing the retention time of each scan.}

\item{valsPerSpect}{Numeric vector with the number of values for each
spectrum.}

\item{ppm}{\code{numeric(1)} defining the maximal tolerated m/z deviation in
consecutive scans in parts per million (ppm) for the initial ROI
definition.}

\item{peakwidth}{\code{numeric(2)} with the expected approximate
peak width in chromatographic space. Given as a range (min, max)
in seconds.}

\item{snthresh}{\code{numeric(1)} defining the signal to noise ratio cutoff.}

\item{prefilter}{\code{numeric(2)}: \code{c(k, I)} specifying the prefilter
step for the first analysis step (ROI detection). Mass traces are only
retained if they contain at least \code{k} peaks with intensity
\code{>= I}.}

\item{mzCenterFun}{Name of the function to calculate the m/z center of the
chromatographic peak. Allowed are: \code{"wMean"}: intensity weighted
mean of the peak's m/z values, \code{"mean"}: mean of the peak's m/z
values, \code{"apex"}: use the m/z value at the peak apex,
\code{"wMeanApex3"}: intensity weighted mean of the m/z value at the
peak apex and the m/z values left and right of it and \code{"meanApex3"}:
mean of the m/z value of the peak apex and the m/z values left and right
of it.}

\item{integrate}{Integration method. For \code{integrate = 1} peak limits
are found through descent on the mexican hat filtered data, for
\code{integrate = 2} the descent is done on the real data. The latter
method is more accurate but prone to noise, while the former is more
robust, but less exact.}

\item{mzdiff}{\code{numeric(1)} representing the minimum difference in m/z
dimension required for peaks with overlapping retention times; can be
negative to allow overlap. During peak post-processing, peaks
defined to be overlapping are reduced to the one peak with the largest
signal.}

\item{fitgauss}{\code{logical(1)} whether or not a Gaussian should be fitted
to each peak. This affects mostly the retention time position of the
peak.}

\item{noise}{\code{numeric(1)} allowing to set a minimum intensity required
for centroids to be considered in the first analysis step (centroids with
intensity \code{< noise} are omitted from ROI detection).}

\item{verboseColumns}{\code{logical(1)} whether additional peak meta data
columns should be returned.}

\item{criticalValue}{\code{numeric(1)}. Suggested values:
(\code{0.1-3.0}). This setting helps determine the the Kalman Filter
prediciton margin of error. A real centroid belonging to a bonafide
peak must fall within the KF prediction margin of error. Much like
in the construction of a confidence interval, \code{criticalVal} loosely
translates to be a multiplier of the standard error of the prediction
reported by the Kalman Filter. If the peak in the XC-MS sample have
a small mass deviance in ppm error, a smaller critical value might be
better and vice versa.}

\item{consecMissedLimit}{\code{integer(1)} Suggested values: (\code{1,2,3}).
While a peak is in the proces of being detected by a Kalman Filter, the
Kalman Filter may not find a predicted centroid in every scan. After 1
or more consecutive failed predictions, this setting informs Massifquant
when to stop a Kalman Filter from following a candidate peak.}

\item{unions}{\code{integer(1)} set to \code{1} if apply t-test union on
segmentation; set to \code{0} if no t-test to be applied on
chromatographically continous peaks sharing same m/z range.
Explanation: With very few data points, sometimes a Kalman Filter stops
tracking a peak prematurely. Another Kalman Filter is instantiated
and begins following the rest of the signal. Because tracking is done
backwards to forwards, this algorithmic defect leaves a real peak
divided into two segments or more. With this option turned on, the
program identifies segmented peaks and combines them (merges them)
into one with a two sample t-test. The potential danger of this option
is that some truly distinct peaks may be merged.}

\item{checkBack}{\code{integer(1)} set to \code{1} if turned on; set to
\code{0} if turned off. The convergence of a Kalman Filter to a peak's
precise m/z mapping is very fast, but sometimes it incorporates erroneous
centroids as part of a peak (especially early on). The \code{scanBack}
option is an attempt to remove the occasional outlier that lies beyond
the converged bounds of the Kalman Filter. The option does not directly
affect identification of a peak because it is a postprocessing measure;
it has not shown to be a extremely useful thus far and the default is set
to being turned off.}

\item{withWave}{\code{logical(1)} if \code{TRUE}, the peaks identified first
with Massifquant are subsequently filtered with the second step of the
centWave algorithm, which includes wavelet estimation.}
}
\value{
A matrix, each row representing an identified chromatographic peak,
    with columns:
    \describe{
    \item{mz}{Intensity weighted mean of m/z values of the peaks across
    scans.}
    \item{mzmin}{Minumum m/z of the peak.}
    \item{mzmax}{Maximum m/z of the peak.}
    \item{rtmin}{Minimum retention time of the peak.}
    \item{rtmax}{Maximum retention time of the peak.}
    \item{rt}{Retention time of the peak's midpoint.}
    \item{into}{Integrated (original) intensity of the peak.}
    \item{maxo}{Maximum intensity of the peak.}
    }

    If \code{withWave} is set to \code{TRUE}, the result is the same as
    returned by the \code{\link{do_findChromPeaks_centWave}} method.
}
\description{
Massifquant is a Kalman filter (KF)-based chromatographic peak
    detection for XC-MS data in centroid mode. The identified peaks
    can be further refined with the \emph{centWave} method (see
    \code{\link{do_findChromPeaks_centWave}} for details on centWave)
    by specifying \code{withWave = TRUE}.
}
\details{
This algorithm's performance has been tested rigorously
    on high resolution LC/(OrbiTrap, TOF)-MS data in centroid mode.
    Simultaneous kalman filters identify peaks and calculate their
    area under the curve. The default parameters are set to operate on
    a complex LC-MS Orbitrap sample. Users will find it useful to do some
    simple exploratory data analysis to find out where to set a minimum
    intensity, and identify how many scans an average peak spans. The
    \code{consecMissedLimit} parameter has yielded good performance on
    Orbitrap data when set to (\code{2}) and on TOF data it was found best
    to be at (\code{1}). This may change as the algorithm has yet to be
    tested on many samples. The \code{criticalValue} parameter is perhaps
    most dificult to dial in appropriately and visual inspection of peak
    identification is the best suggested tool for quick optimization.
    The \code{ppm} and \code{checkBack} parameters have shown less influence
    than the other parameters and exist to give users flexibility and
    better accuracy.
}
\examples{

## Load the test file
faahko_sub <- loadXcmsData("faahko_sub")

## Subset to one file and restrict to a certain retention time range
data <- filterRt(filterFile(faahko_sub, 1), c(2500, 3000))

## Get m/z and intensity values
mzs <- mz(data)
ints <- intensity(data)

## Define the values per spectrum:
valsPerSpect <- lengths(mzs)

## Perform the peak detection using massifquant - setting prefilter to
## a high value to speed up the call for the example
res <- do_findChromPeaks_massifquant(mz = unlist(mzs), int = unlist(ints),
    scantime = rtime(data), valsPerSpect = valsPerSpect,
    prefilter = c(3, 10000))
head(res)
}
\references{
Conley CJ, Smith R, Torgrip RJ, Taylor RM, Tautenhahn R and Prince JT
"Massifquant: open-source Kalman filter-based XC-MS isotope trace feature
detection" \emph{Bioinformatics} 2014, 30(18):2636-43.
}
\seealso{
\code{\link{massifquant}} for the standard user interface method.

Other core peak detection functions: 
\code{\link{do_findChromPeaks_centWave}()},
\code{\link{do_findChromPeaks_centWaveWithPredIsoROIs}()},
\code{\link{do_findChromPeaks_matchedFilter}()},
\code{\link{do_findPeaks_MSW}()}
}
\author{
Christopher Conley
}
\concept{core peak detection functions}
