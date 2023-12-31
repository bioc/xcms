% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/RDataParam.R
\name{RDataParam}
\alias{RDataParam}
\alias{storeResults,XcmsExperiment,RDataParam-method}
\title{Store `XcmsExperiment` object as .RData file}
\usage{
RDataParam(fileName = tempfile())

\S4method{storeResults}{XcmsExperiment,RDataParam}(object, param)
}
\arguments{
\item{fileName}{for `RDataParam` `character(1)`, defining the file name. The
default will be `tempfile()`.}

\item{object}{\code{MsExperiment} or \code{XcmsExperiment} The data object that needs
to be saved.}

\item{param}{The parameter object selecting and configuring the format for
saving. It can be one of the following classes: \code{\link{RDataParam}},
\code{\link{PlainTextParam}}, or \code{MzTabMParam}.}
}
\value{
for `RDataParam`: a `RDataParam` class. `storeResults` does not
return anything but saves the object to a RData file.
}
\description{
The `RDataParam` class and method allow users to save an `XcmsExperiment`
object as an .RData file with a chosen filename. The object gets exported
using [`save()`] function.  This `param` class and method are part of the
possible dispatch of the generic function `storeResults`.
}
\examples{

## Load a test data set with detected peaks
faahko_sub <- loadXcmsData("faahko_sub2")

## Define param 
param <- RDataParam(fileName = "example_xcms_object")

## Save as RData
storeResults(object = faahko_sub, param = param)

}
\seealso{
Other xcms result export formats.: 
\code{\link{PlainTextParam}}
}
\author{
Philippine Louail
}
\concept{xcms result export formats.}
