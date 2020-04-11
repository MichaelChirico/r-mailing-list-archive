#!/usr/local/bin/Rscript
library(rvest)

URL_BASE ='https://stat.ethz.ch/pipermail'
today = as.POSIXlt(Sys.time())
mailing_lists = list(
  c(name = 'r-devel', current = format(today, '%Y-%B.txt')),
  c(name = 'r-package-devel',
    current = with(today, sprintf('%dq%d.txt', year + 1900L, mon %/% 3L + 1L))),
  c(name = 'r-help', current = format(today, '%Y-%B.txt'))
)
for (ii in seq_along(mailing_lists)) {
  this_list = mailing_lists[[ii]]
  URL = file.path(URL_BASE, this_list['name'], '')

  outdir = this_list['name']
  dir.create(outdir, recursive = TRUE, showWarnings = FALSE)

  # Always re-write current period
  extant = setdiff(list.files(outdir), this_list['current'])

  zips = URL %>% read_html %>%
    # linked under "Gzip'd Text NNN KB"
    html_nodes(xpath = '//a[contains(text(), "Gzip")]') %>%
    # only download new archives
    html_attr('href') %>% setdiff(sprintf('%s.gz', extant)) %>%
    # sort should be unnecessary
    sprintf('%s%s', URL, . ) %>% sort

  if (length(zips)) {
    message('Acquiring ', length(zips), ' archives: ',
            basename(head(zips, 1L)), ' - ', basename(tail(zips, 1L)))
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
}