# Copyright 2014 52°North Initiative for Geospatial Open Source Software GmbH
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#' License header
#'
#' \code{license_header} check if license header is present in all the R source code files of the package.
#'
#' @param pkg package name, used in \code{devtools:::find_code(..)}.
#' @param header a path to the header file to be used
#' @param add boolean variable for automatically adding the header if it is missing - \emph{BETA},
#'      the function will not replace an existing but slightly different header!
#' @return A human readable message of the result of the function, including the files that were changed (if any).
#' @examples
#' \dontrun{
#'  license_header()
#' }
#' @import futile.logger
license_header <- function(pkg = ".", header = "inst/license-header", add = FALSE) {
    if (!requireNamespace("devtools", quietly = TRUE)) {
        stop("devtools required to run license_header(). Please install.", call. = FALSE)
    }

    files <- devtools:::find_code(devtools::as.package(pkg))
    flog.debug("Checking license headers of %s files using '%s', adding if missing = %s", length(files), header, add)

    .result <- .addLicenseHeaderToFiles(files, header, add)
    return(.result)
}

#' License header check
#'
#' \code{has_license_header} checks if license header is present in all the R source code files of the package using \code{licesen_header()}.
#'
#' @inheritParams license_header
#' @return \code{TRUE} if all files have the header, \code{FALSE} otherwise.
#' @examples
#' \dontrun{
#'  has_license_header()
#' }
#' @import futile.logger
has_license_header <- function(pkg = ".", header = "inst/license-header") {
    .result <- license_header(pkg = pkg, header = header)
    .substr <- substr(.result, 1, 7)
    .substr <- tolower(.substr)
    return(.substr == "success")
}

.linesHaveHeader <- function(lines, header_content) {
    sizeOfHeader <- length(header_content)
    sizeOfLines <- length(lines)
    if(sizeOfLines < sizeOfHeader) {
        flog.debug("File has %s lines but header has already %s", sizeOfLines, sizeOfHeader)
        return(FALSE)
    }

    for(i in 1:sizeOfHeader) {
        flog.trace("Comparing '%s' (from file) with '%s' (from header)", lines[i], header_content[i])
        if(lines[i] != header_content[i]) {
            flog.debug("License header is not set, line %s differs: '%s' vs. '%s'", i, lines[i], header_content[i])
            return(FALSE)
        }
    }

    return(TRUE)
}

.addLicenseHeaderToFiles <- function (files, header = "inst/license-header", add = FALSE) {
    flog.trace("Checking files %s", toString(paste(files)))

    files_missing_header <- list()

    headerConn <- file(file.path(devtools::as.package(".")$path, header), 'r+')
    header_content <- readLines(headerConn)
    close(headerConn)
    flog.trace("Header: %s", paste(header_content, sep = "", collapse = ""))

    # check if files starts with license header
    for(f in files) {
        flog.trace("Checking license of file %s", f)

        fConn <- file(f, 'r+')
        lines <- readLines(fConn)

        hasHeader <- .linesHaveHeader(lines, header_content)
        if(hasHeader)
            flog.trace("File %s already has a header", f)
        else {
            files_missing_header <- c(files_missing_header, f)
            flog.trace("File %s is missing the header", f)

            if(add) {
                flog.trace("Adding header to file %s", f)
                writeLines(c(header_content, lines, sep = "\n"), con = fConn)
            }
        }

        close(fConn)
    }

    flog.trace("%s files missing header: %s", length(files_missing_header), toString(files_missing_header))
    if(length(files_missing_header) < 1)
        return(paste0("Success: All files have the license header specified in ", header))
    else return(paste0("Failure: Files missing the header: ", paste0(files_missing_header)))
}
