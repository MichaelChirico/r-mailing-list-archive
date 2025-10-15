#!/usr/local/bin/Rscript
library(xml2)

URL_BASE ='https://stat.ethz.ch/pipermail'
# POSIXlt facilitates formatting as quarter
today = as.POSIXlt(Sys.time())

mailing_lists = read.table(header = TRUE, text = "
name               frequency
r-devel            month
r-package-devel    quarter
r-sig-mac          month
r-help             month
r-sig-geo          month
r-sig-finance      quarter
r-sig-mixed-models quarter
")

for (ii in seq_len(nrow(mailing_lists))) {
  outdir = mailing_lists$name[ii]

  URL = file.path(URL_BASE, outdir)
  dir.create(outdir, recursive = TRUE, showWarnings = FALSE)

  # Always re-write current period
  current_period <- switch(mailing_lists$frequency[ii],
    annual = format(today, '%Y'),
    quarter = with(today, sprintf('%dq%d.txt', year + 1900L, mon %/% 3L + 1L)),
    month = format(today, '%Y-%B')
  )
  extant_gz = outdir |>
    list.files() |>
    setdiff(current_period) |>
    paste0('.gz')

  zips = URL |>
    read_html() |>
    # linked under "Gzip'd Text NNN KB"
    xml_find_all('//a[contains(text(), "Gzip")]') |>
    xml_attr('href') |>
    # only download new archives
    setdiff(extant_gz) |>
    file.path(URL, ..gzpath = _ ) |>
    # this should be unnecessary
    sort()

  if (length(zips)) {
    message(sprintf(
      'Acquiring %d %s archives: %s - %s',
      length(zips), outdir, basename(head(zips, 1L)), basename(tail(zips, 1L))
    ))
  } else {
    message('No new ', outdir, ' archives to acquire')
  }

  for (zip in zips) {
    local({
      zip_tmp <- tempfile()
      on.exit(unlink(zip_tmp))
      download.file(zip, zip_tmp)
      local({
        zip_conn <- gzfile(zip_tmp)
        on.exit(close(zip_conn))
        outfile <- gsub('.gz', '', basename(zip), fixed = TRUE)
        zip_conn |>
          readLines() |>
          writeLines(file.path(outdir, outfile))
      })
    })
  }
}
