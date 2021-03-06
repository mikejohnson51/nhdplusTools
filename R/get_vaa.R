#' @title File path to value added attribute (vaa) Cache
#' @description nhdplusTools will download and cache an `fst` file with
#' NHDPlusV2 attribute data sans geometry. This function returns the
#' file path to the cached file. Will use the user cache dir indicated
#' by \link[rappdirs]{user_cache_dir}.
#' @inherit download_vaa details
#' @return file.path character
#' @importFrom rappdirs user_cache_dir
#' @export
#' @examples
#' get_vaa_path()

get_vaa_path <- function() {
  user_cache_dir("nhdplus-vaa/nhdplusVAA.fst")
}

#' @title Available NHDPlusV2 Attributes
#' @description Find variables available from the NHDPlusV2 attribute data.frame
#' @inherit download_vaa details
#' @return character vector
#' @importFrom fst metadata_fst
#' @export
#' @examples
#' get_vaa_names()

get_vaa_names <- function(){
 fst::metadata_fst(get_vaa_path())
}

#' @title NHDPlusV2 Attribute Subset
#' @description Return requested NHDPlusv2 Attributes
#' @inherit download_vaa details
#' @param atts character The variable names you would like, always includes comid
#' @param path character path where the file should be saved. Default is a
#' persistent system cache as retrieved by \link[rappdirs]{user_cache_dir}.
#' Also see: \link{get_vaa_path}
#' @param download logical if TRUE, the default, will download VAA table if not
#' found at path.
#' @return data.frame
#' @export
#' @examples
#' \dontrun{
#' # NOTE: path = tempfile() for demo only.
#' temp <- tempfile()
#' get_vaa("slope", path = temp)
#' get_vaa(c("slope", "lengthkm"), path = temp)
#' }
#' @importFrom fst read.fst

get_vaa <- function(atts = NULL,
                    path = get_vaa_path(),
                    download = TRUE) {

  if(!file.exists(path)){
    if(download) {
      message("didn't find data, downloading.")
      path <- download_vaa(path = path)
    } else {
      stop("need to download data: run `download_vaa()`")
    }
  }

  avaliable_names = get_vaa_names()[["columnNames"]]

  bad_atts = atts[!atts %in% avaliable_names]
  atts      = atts[atts %in% avaliable_names]
  if(length(bad_atts) > 0){
    message(paste(bad_atts, collapse = ", "), " not in vaa data. Ignoring...")
  }

  if(is.null(atts)){
    return(fst::read.fst(path))
  }

  if(all(atts %in% avaliable_names)){
    return(fst::read_fst(path, c('comid', atts)))
  }

}

#' @title Download nhdplusVAA data from HydroShare
#' @description downloads and caches nhdplusVAA data on your computer
#' @details The VAA data is a aggregate table of information from the NHDPlusV2
#' elevslope.dbf(s), PlusFlowlineVAA.dbf(s); and NHDFlowlines. All data
#' originates from the EPA NHDPlus Homepage
#' \href{https://www.epa.gov/waterdata/get-nhdplus-national-hydrography-dataset-plus-data}{here}.
#' To see the location of cached data on your machine use
#' \code{\link{get_vaa_path}}.
#' To view aggregate data and documentation, see
#' \href{https://www.hydroshare.org/resource/6092c8a62fac45be97a09bfd0b0bf726/}{here}
#' @inheritParams  get_vaa
#' @param force logical. Force data re-download. Default = FALSE
#' @return path to cached data
#' @export
#' @importFrom httr GET progress write_disk

download_vaa <- function(path = get_vaa_path(), force = FALSE) {

  if (file.exists(path) & !force) {
    message("File already cached")
  } else {
    dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)

    resp <- httr::GET(vaa_hydroshare,
                      httr::write_disk(path, overwrite = TRUE),
                      httr::progress())

    if (resp$status_code != 200) {
      stop("Download unsuccessfull :(")
    }
  }
  # return file path
  return(path)
}

