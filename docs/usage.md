# Usage

> [!note] Planned
> The app is not built yet; PLAN-00001 delivers what this page describes,
> which follows passalong-android's
> [usage doc](https://github.com/joelee/passalong-android/blob/9c2bf5974630237fd4a0b28472afadc7a488c8da/docs/usage.md)
> screen for screen. Only the iOS differences are listed here.

Prepare the server first, as passalong's README describes under
[server setup](https://github.com/joelee/passalong#server-setup), or get
a workspace, a certificate pin, and an API key from a
[passalong-server](https://github.com/joelee/passalong-server)'s
operator.

## Setup

The same steps as on Android, for an SSH server (the device's public key,
the server, the host-key fingerprint to confirm) or a passalong-server
(the URL, the certificate pin or *Trust the system*, the API key in a
secure field, the server's answer, and the "not encrypted" confirmation).
Nothing is written until you confirm.

## Choose

| Touch | Action | TUI key |
|---|---|---|
| Tap a row | Load: text goes to the pasteboard; files and clipboard images are saved to the app's Documents folder (Files app, *On My iPhone › Passalong*), checked against their SHA-256 first | Enter |
| Long press a row | Context menu: *Load*, *Show content*, *Details*, *Delete* | `c`, `g`, `d` |
| Pull down, search field | Filter by id, name or preview, device, or kind | `/` |
| Pull to refresh | From the list cache when it is fresh, otherwise the server | `r` |
| Menu, *Read from the server* | Read every item from the server and rewrite the cache | `R` |
| Menu, *Help* | The passalong version, what it is, and these actions | `?` |
| Menu, *Set up again* | Back to the setup screen | |

iOS apps do not quit themselves, so there is no *Quit*; swipe back or
*Done* closes the filter, a sheet, or the content view.
