# The Electronic Flight Bag (EFB)

The E-Jet comes with a built-in Electronic Flight Bag (EFB), installed on a
tablet available on the flight deck.

However, for various reasons, we cannot ship a complete set of charts for the
entire world with the aircraft - it would be an incredibly large download, we
would have to provide new charts for each AIRAC cycle, and, most importantly,
there no charts are available that we can legally redistribute under GPL.

Further, because FlightGear cannot natively display PDF files, we cannot load
most charts directly; they have to be converted to PNG first.

Hence, in order to make use of the EFB, a companion application is required
that runs an HTTP server on `http://localhost:7675`. (For the time being, this
address is hard-coded, but will probably become configurable soon).

## The EFB Companion Protocol

Any application you like can act as the EFB companion, as long as it exposes an
HTTP server. The server must support two types of calls: listings, and charts.

### Listings

Listings are returned as XML documents of the following format:

```
<listing>
  <file>
    <name>A descriptive name</name>
    <path>The full URL path to download the file</path>
    <type>pdf</type>
    <!-- currently, the only supported type is 'pdf' -->
  </file>
  <directory>
    <name>A descriptive name</name>
    <path>The full URL path to the listing</path>
  </directory>
  <!-- more <file> or <directory> entries may follow -->
</listing>
```

### Charts

Charts should be served as `image/png`. If the `p=...` query string parameter
is given, it indicates the 0-based page number to return from the document; if
it is not given, then the Companion should return the first page of the
document.

### Root URL

The root URL (`/`) is expected to return a listing. The type of all other
resources is inferred from the listings that link to it: any path referenced
through a `<directory>` is expected to be a listing, and any path referenced
through a `<file>` is expected to be a PNG image.

The root URL will be the first resource requested when the flight bag app
starts up.
