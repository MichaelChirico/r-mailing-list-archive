#!/usr/local/bin/R
library(rvest)

URL = 'https://stat.ethz.ch/pipermail/r-devel/'

outdir = 'txt'
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)

# If current month exists in the archive, overwrite it (it shouldn't exist)
extant = setdiff(list.files(outdir), format(Sys.Date(), '%Y-%B.txt'))

zips = URL %>% read_html %>%
  # linked under "Gzip'd Text NNN KB"
  html_nodes(xpath = '//a[contains(text(), "Gzip")]') %>%
  # only download new archives
  html_attr('href') %>% setdiff(sprintf('%s.gz', extant), . ) %>%
  # sort should be unnecessary
  sprintf('%s%s', URL, . ) %>% sort

if (length(zips)) {
  message('Acquiring ', length(zips), ' archives: ',
          head(zips, 1L), ' - ', tail(zips, 1L))
} else {
  message('No new zips to acquire')
}

for (zip in zips) {
  download.file(zip, tmp <- tempfile())
  conn <- gzfile(tmp)
  outfile <- gsub('.gz', '', basename(zip), fixed = TRUE)
  writeLines(readLines(conn), file.path(outdir, outfile))
  close(conn)
  unlink(tmp)
}
