#!/usr/local/bin/Rscript
library(xml2)

URL_BASE ='https://stat.ethz.ch/pipermail'
# POSIXlt facilitates formatting as quarter
today = as.POSIXlt(Sys.time())

mailing_lists = list(
  c(name = 'r-devel', frequency = 'month'),
  c(name = 'r-package-devel', frequency = 'quarter'),
  c(name = 'r-sig-mac', frequency = 'month'),
  c(name = 'r-help', frequency = 'month'),
  c(name = 'r-announce', frequency = 'annual'),
  c(name = 'r-sig-geo', frequency = 'month'),
  c(name = 'r-sig-finance', frequency = 'quarter'),
  c(name = 'r-sig-mixed-models', frequency = 'quarter')
)

for (ii in seq_along(mailing_lists)) {
  this_list = mailing_lists[[ii]]
  outdir = this_list[['name']]

  URL = file.path(URL_BASE, outdir)
  dir.create(outdir, recursive = TRUE, showWarnings = FALSE)

  # Always re-write current period
  current_period <- switch(this_list[['frequency']],
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
