\name{collect-methods}
\docType{methods}
\alias{collect-methods}
\alias{collect}
\alias{collect,xcmsFragments-method}
\title{Collecting Peaks into xcmsFragments from several ms-runs using xcmsSet and xcmsRaw}
\description{
 
}
\section{Methods}{
\describe{
\item{object = "xcmsFragments"}{
  \code{
    collect(object, ...)
   }
}
}}
\arguments{
  \item{object}{(empty) \code{\link{xcmsFragments-class}} object}
  \item{xcmsS}{A \code{\link{xcmsSet-class}} object which contains picked ms1-peaks from several experiments}
  \item{compMethod}{("floor", "round", "none"): compare-method which is used to find the parentpeak of a MSnpeak through comparing the MZ-values of the  MS1peaks with the MSnParentPeaks.}
  \item{snthresh, mzgap, uniq}{these are the paramters for the getspec-peakpicker included in xcmsRaw.}
}
\details{
  After running collect(xFragments,xSet) The peaktable of the xcmsFragments includes the ms1Peaks from all experinemts stored in a xcmsSet-object. Further it contains the relevant msN-peaks from the xcmsRaw-objects, which were created temporarily with the paths in xcmsSet.
}
c("peakID", "MSnParentPeakID","msLevel","rt", "mz", "intensity","sample")
\value{
  A matrix with columns:
  \item{peakID}{
    unique identifier of every peak
  }
  \item{MSnParentPeakID}{
    PeakID of the parentpeak of a msLevel>1 - peak, it is 0 if the peak is msLevel 1.
  }
  \item{msLevel}{
    The msLevel of the peak.
  }
  \item{rt}{
    retention time of the peak midpoint
  }
  \item{mz}{
    the mz-Value of the peak
  }
  \item{intensity}{
    the intensity of the peak
  }
 \item{sample}{
    the number of the sample from the xcmsSet
  }
}
\seealso{
 }
\keyword{methods}