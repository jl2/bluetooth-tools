;; package.lisp
;; Copyright © 2024 Jeremiah LaRocco <jeremiah_larocco@fastmail.com>

;; Permission to use, copy, modify, and/or distribute this software for any
;; purpose with or without fee is hereby granted, provided that the above
;; copyright notice and this permission notice appear in all copies.

;; THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
;; WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
;; MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
;; ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
;; WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
;; ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
;; OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

(defpackage :bluetooth-tools

  (:nicknames :bluetooth)

  (:use #:cl
        #:alexandria
        )

  (:export

   #:inspect-device
   #:first-with-interface
   
   #:scan

   #:connect
   #:disconnect

   #:pair

   #:device-p
   #:service-p

   #:list-adapters
   #:list-devices
   #:list-media-controllers
   #:list-objects
   #:list-services
   
   #:battery-levels

   #:volume-up
   #:volume-down

   #:read-gatt-characteristic-by-service
   #:read-gatt-characteristic-by-uuid

   #:main))
