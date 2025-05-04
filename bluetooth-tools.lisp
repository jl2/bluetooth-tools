;; bluetooth-tools.lisp
;; Copyright (c) 2024 Jeremiah LaRocco <jeremiah_larocco@fastmail.com>

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

(in-package :bluetooth-tools)

(defun inspect-device (&optional (device-path
                                  (dbt:managed-object-name
                                   (first-with-interface "org.bluez.MediaControl1"))))
  "Inspect a Bluez device object by device path.  Default path is the first device implementing MediaControl1."
  (dbt:inspect-introspected-object :system "org.bluez"
                                   device-path))

(defun first-with-interface (interface)
  "Find the first device implementing `interface`."
  (loop
    :for device :in (list-devices :full t)
    :when (dbt:has-interface device interface)
      :return device))

(defun volume-up (&key
                    (steps 1)
                    (device-path (dbt:managed-object-name
                                  (first-with-interface "org.bluez.MediaControl1"))))
  "Execute VolumeUp method one or more times on a org.bluez.MediaControl1 object."
  (dbus:with-open-bus (bus (dbt:get-bus :system))
    (dotimes (i steps)
      (dbus:invoke-method (dbus:bus-connection bus)
                          "VolumeUp"
                          :path device-path
                          :interface "org.bluez.MediaControl1"
                          :destination "org.bluez"))))

(defun volume-down (&key
                      (steps 1)
                      (device-path (dbt:managed-object-name
                                    (first-with-interface "org.bluez.MediaControl1"))))
  "Execute VolumeDown method one or more times on a org.bluez.MediaControl1 object."
  (dbus:with-open-bus (bus (dbt:get-bus :system))
    (dotimes (i steps)
      (dbus:invoke-method (dbus:bus-connection bus)
                          "VolumeDown"
                          :path device-path
                          :interface "org.bluez.MediaControl1"
                          :destination "org.bluez"))))

(defun list-objects ()
  "List all org.bluez managed objects."
  (dbus:with-open-bus (bus (dbt:get-bus :system))
    (dbus:get-managed-objects bus "org.bluez" "/")))

(defun device-p (object)
  "Test if object looks like a bluetooth device."
  (dbt:has-interface object "org.bluez.Device1"))

(defun service-p (object)
  "Test if object looks like a bluetooth service."
  (cl-ppcre:scan-to-strings
   "^/org/bluez/hci[0-9]+/dev_\(..\)_\(..\)_\(..\)_\(..\)_\(..\)_\(..\)/service.*$"
   (dbt:managed-object-name object)))


(defun list-adapters (&key (full nil))
  "Return a list of Bluetooth adapters on the host."
  (let ((adapters (remove-if-not (rcurry #'dbt:has-interface "org.bluez.Adapter1") (list-objects))))
    (if full
        adapters
        (loop :for ada :in adapters
              :for adapter = (dbt:managed-object-value ada)
              :collect (nested-get adapter "org.bluez.Adapter1" "Name")))))


(defun list-media-controllers ()
  "List Bluetooth devices that implement the org.bluez.MediaControl1 interface."
  (remove-if-not
   (rcurry #'dbt:has-interface "org.bluez.MediaControl1")
   (list-objects)))

(defun scan (&key (timeout 5)
                  (adapter (dbt:managed-object-name (first (list-adapters :full t)))))
  "Enable Bluetooth discovery on the specified adapter for timeout seconds."
  (dbus:with-open-bus (bus (dbt:get-bus :system))
    (dbus:invoke-method (dbus:bus-connection bus)
                        "StartDiscovery"
                        :arguments '()
                        :path adapter
                        :signature ""
                        :interface "org.bluez.Adapter1"
                        :destination "org.bluez")


    (sleep timeout)
    (dbus:invoke-method (dbus:bus-connection bus)
                        "StopDiscovery"
                        :arguments '()
                        :path adapter
                        :signature ""
                        :interface "org.bluez.Adapter1"
                        :destination "org.bluez")))

(defun nested-get (dev &rest path)
  "(dbt:dbt:find-value (dbt:dbt:find-value... (dbt:dbt:find-value dev (car path) (cadr path) ...)"
  (loop :for val = dev :then (dbt:find-value val key)
        :for key :in path
        :finally (return val)))


(defun list-devices (&key
                          (interfaces nil)
                          (full nil))
  "List Bluetooth devices that implement the given list of interfaces, or all devices.
If full, return full objects, otherwise return a list of user friendly device names."
  (flet ((predicate (obj)
           (and (dbt:has-interface obj "org.bluez.Device1")
                (every (curry #'dbt:has-interface obj)
                       (ensure-list interfaces)))))

    (let ((devs (remove-if-not #'predicate (list-objects))))
      (if full
          devs
          (loop
            :for device :in devs
            :for dev = (dbt:managed-object-value device)
            :for name = (nested-get dev "org.bluez.Device1" "Name")
            :collect (if name name
                         (dbt:managed-object-name device)))))))

(defun connect (device-path)
  "Connect to a Bluettooth device by its device-path"
  (dbt:invoke-method-simple :system
                                   "org.bluez"
                                   device-path
                                   "org.bluez.Device1"
                                   "Connect"))
(defun pair (device-path)
  "Pair with a Bluettooth device by its device-path"
  (dbt:invoke-method-simple :system
                                   "org.bluez"
                                   device-path
                                   "org.bluez.Device1"
                                   "Pair"))

(defun disconnect (device-path)
  "Disconnect from a Bluettooth device by its device-path"
  (dbt:invoke-method-simple :system
                                   "org.bluez"
                                   device-path
                                   "org.bluez.Device1"
                                   "Disconnect"))

(defun list-services (&optional device)
  "List Bluetooth services on the specified device, or all Bluetooth services if no device given."
  (remove-if-not
   (lambda (value)
     (and (service-p value)
          (if device
              (cl-ppcre:scan (format nil "^~a.*" device) (car value))
              t)))
   (list-objects)))

(defun battery-levels ()
  "Return a list of (device name . battery level) for all connected Bluetooth devices."
  (loop
    :for device :in (list-devices :interfaces '("org.bluez.Battery1")
                                  :full t)
    :for dev = (dbt:managed-object-value device)
    :for is-connected = (nested-get dev "org.bluez.Device1" "Connected")
    :for is-paired = (nested-get dev "org.bluez.Device1" "Paired")
    :when  (or is-paired is-connected)
      :collect (cons (nested-get dev "org.bluez.Device1" "Name")
                     (nested-get dev "org.bluez.Battery1" "Percentage"))))

(defun read-gatt-characteristic-by-service (service-path)
  "Read a GATT characteristic by service path."
  (declare (type string service-path))
  (let ((values (dbus-tools:invoke-method-simple :system
                                                 "org.bluez"
                                                 service-path
                                                 "org.bluez.GattCharacteristic1"
                                                 "ReadValue"
                                                 "a{sv}"
                                                 nil)))
    (make-array (length values)
                :initial-contents values
                :element-type '(unsigned-byte 8))))

(defun read-gatt-characteristic-by-uuid (device uuid)
  "Read a GATT characteristic by UUID."
  (declare (type string device uuid))
  (let ((services (list-services device)))
    (flet ((matches-uuid (service)
             (string= (dbt:find-value
                       (dbt:find-value (dbt:managed-object-value service)
                                      "org.bluez.GattCharacteristic1")
                       "UUID")
                      uuid)))
      (read-gatt-characteristic-by-service (car (find-if #'matches-uuid
                                                         services))))))
