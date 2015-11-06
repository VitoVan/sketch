;;;; color.lisp

(in-package #:sketch)

;;;   ____ ___  _     ___  ____
;;;  / ___/ _ \| |   / _ \|  _ \
;;; | |  | | | | |  | | | | |_) |
;;; | |__| |_| | |__| |_| |  _ <
;;;  \____\___/|_____\___/|_| \_\

;;; General

(defstruct color
  (red 0.0)
  (green 0.0)
  (blue 0.0)
  (hue 0.0)
  (saturation 0.0)
  (brightness 0.0)
  (alpha 1.0))

(defun rgb-to-hsb (r g b)
  (let* ((c-max (max r g b))
	 (c-min (min r g b))
	 (delta (- c-max c-min))
	 (hue (* 60 (cond ((= delta 0) 0)
			  ((= c-max r) (mod (/ (- g b) delta) 6))
			  ((= c-max g) (+ (/ (- b r) delta) 2))
			  ((= c-max b) (+ (/ (- r g) delta) 4)))))
	 (saturation (if (zerop c-max)
			 0
			 (/ delta c-max)))
	 (brightness c-max))
    (list (/ hue 360) saturation brightness)))

(defun hsb-to-rgb (h s b)
  (let* ((h (mod (* h 360) 360))
	 (c (* b s))
	 (x (* c (- 1 (abs (- (mod (/ h 60) 2) 1)))))
	 (m (- b c)))
    (mapcar (lambda (x) (+ m x))
	    (aref `#((,c ,x 0) (,x ,c 0) (0 ,c ,x)
		     (0 ,x ,c) (,x 0 ,c) (,c 0 ,x))
		  (floor (/ h 60))))))

(defun rgb (red green blue &optional (alpha 1.0))
  (destructuring-bind (red green blue alpha)
      (mapcar #'clamp-1 (list red green blue alpha))
    (let ((hsb (rgb-to-hsb red green blue)))
      (make-color :red red :green green :blue blue :alpha alpha
		  :hue (elt hsb 0) :saturation (elt hsb 1) :brightness (elt hsb 2)))))

(defun hsb (hue saturation brightness &optional (alpha 1.0))
  (destructuring-bind (hue saturation brightness alpha)
      (mapcar #'clamp-1 (list hue saturation brightness alpha))    
    (let ((rgb (hsb-to-rgb hue saturation brightness)))
      (make-color :hue hue :saturation saturation :brightness brightness :alpha alpha
		  :red (elt rgb 0) :green (elt rgb 1) :blue (elt rgb 2)))))

(defun gray (amount &optional (alpha 1.0))
  (rgb amount amount amount alpha))

(defun rgb-255 (r g b &optional (a 255))
  (rgb (/ r 255) (/ g 255) (/ b 255) (/ a 255)))

(defun hsb-360 (h s b &optional (a 255))
  (hsb (/ h 360) (/ s 100) (/ b 100) (/ a 255)))

(defun gray-255 (g &optional (a 255))
  (gray (/ g 255) (/ a 255)))

(defun hex-to-color (string)
  (destructuring-bind (r g b &optional (a 1.0))
      (let* ((bits (case (length string)
		     ((3 4) 4)
		     ((6 8) 8)
		     (t (error "~a is invalid hex color." string))))
	     (groups (group-bits (parse-integer string :radix 16 :junk-allowed t)
				 :bits bits)))
	(pad-list (mapcar (lambda (x) (/ x (if (= bits 4) 15 255))) groups)
		  0
		  (if (= 4 bits)
		      (length string)
		      (/ (length string) 2))))
    (rgb r g b a)))

(defun color-rgba (color)
  (list (color-red color)
	(color-green color)
	(color-blue color)
	(color-alpha color)))

(defun color-hsba (color)
  (list (color-hue color)
	(color-saturation color)
	(color-brightness color)
	(color-alpha color)))

(defun lerp-color (c1 c2 amount &key (mode :hsb))
  (let ((a (clamp-1 amount)))
    (flet ((norm (field)
	     (normalize a 0.0 1.0
			:out-low (slot-value c1 field) :out-high (slot-value c2 field))))
      (if (eq mode :hsb)
	  (apply #'hsb (mapcar #'norm '(hue saturation brightness alpha)))
	  (apply #'rgb (mapcar #'norm '(red green blue alpha)))))))

(defun random-color ()
  (rgb (random 1.0) (random 1.0) (random 1.0)))