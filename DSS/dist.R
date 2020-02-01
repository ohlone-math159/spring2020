#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)

# reads a file, strips answers, *overwrites the original*
strip_answers_and_overwrite <- function(f){
  lines <- readLines(f)
  n <- length(lines)
  rec = rep(TRUE, n)
  keep <- TRUE
  for (i in 1:n){
    if (grepl("## Question ", lines[i]))
      keep <- TRUE
    if (grepl("## Answer ", lines[i]))
      keep = FALSE
    rec[i] <- keep
  }
  writeLines(lines[rec], f)
}

make_bundles <- function(..., student=FALSE,
                        output_format = c("html_document", "pdf_document")){

  chapters <- c("INTRO", "CAUSAL_EFFECTS", "POPULATION_CHARACTERISTICS")
  chs <- c(...)
  if (!is.null(chs)) # of they specified any in particular, override the list
    chapters <- chs

  bundletype <- ifelse(student, "student", "instructor")

  builddir <- paste0("dss-", bundletype)
  if (dir.exists(builddir))
    unlink(builddir, recursive = TRUE)
  dir.create(builddir)
  file.copy(chapters, builddir, recursive = TRUE)

  rmds <- list.files(builddir, recursive = TRUE, pattern=".Rmd",
                     full.names = TRUE)
  for (fn in rmds){
    if (student)
      strip_answers_and_overwrite(fn)
    rmarkdown::render(fn, output_format)
  }

  stopfilenames <- ifelse(student, # files to leave out of the zips
                          "(README.md)|(lesson-plan.md)|(pics)", "README.md")

  # unless specific chapters were mentioned in ..., a big zip
  if (is.null(chs)){
    files <- list.files(builddir, recursive = TRUE, full.names = TRUE)
    zip(paste0(builddir, ".zip"), files[!grepl(stopfilenames, files)])
  }
  # and always separate chapter zips
  for (ch in chapters){
    files <- list.files(file.path(builddir, ch), recursive = TRUE,
                        full.names = TRUE)
    zip(paste0("dss-", bundletype, "-", ch, ".zip"),
        files[!grepl(stopfilenames, files)])
  }
}

if (length(args)==0){
  make_bundles()
} else {
  if (length(args)==1 && args[1] == "student"){
    make_bundles(student=TRUE)
  } else {
    stop('Usage: [Rscript] dist.R [student]')
  }
}



