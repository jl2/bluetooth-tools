# Build bluetooth-tools

bluetooth-tools: manifest.txt *.lisp *.asd
	buildapp --output bluetooth-tools \
             --manifest-file manifest.txt \
             --load-system asdf \
             --load-system sb-posix \
             --load-system alexandria \
             --load-system bluetooth-tools\
             --entry 'bluetooth-tools:main'

test: t/*.lisp *.lisp *.asd
	sbcl --eval "(ql:quickload :bluetooth-tools.test)" \
		 --eval "(setf 5am::*on-error* :debug)" \
		 --eval "(5am:run-all-tests :summary :suite)" \
		 --eval "(quit)"

manifest.txt: *.asd
	sbcl --no-userinit \
         --no-sysinit \
         --non-interactive \
         --load ~/quicklisp/setup.lisp \
         --eval '(ql:quickload :alexandria)' \
         --eval '(ql:quickload :bluetooth-tools)' \
		 --eval '(ql:write-asdf-manifest-file "manifest.txt")'

clean:
	rm -Rf manifest.txt  *.fasl

.PHONY: clean test
