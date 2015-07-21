(in-package #:cl-neovim)


(eval-when (:compile-toplevel)

  (defun string->symbol (str) "Convert string into symbol." (intern (substitute #\- #\_ (format nil "~:@(~A~)" str)))) 

  (defun parse-args (args)
    "Convert nvim's api representation of args into something we can use in lisp."
    (cond ((listp args) (mapcar #'(lambda (arg) (string->symbol (second arg))) args))
          ((stringp args) (list (string->symbol args)))
          (t NIL)))

  (defun setterp (name) "Is name a setter?" (search "set_" name))

  (defun drop-substring (str substr)
    "Remove first occurence of substr in str."
    (aif (search substr str)
      (concatenate 'string (subseq str 0 it) (subseq str (+ it (length substr))))  
      str))

  (defun clean-up-name (name &optional (modifiers '("vim_" "get_" "set_")))
    "Removes all substrings specified in modifiers from name."
    (if modifiers
      (clean-up-name (drop-substring name (first modifiers)) (rest modifiers))
      name)))

(defmacro desc->lisp-function (name args ret can-fail deferred &optional lisp-name)
  "Create and export functions from the parsed nvim's api."
  (declare (ignore ret can-fail deferred))
  (let ((args (parse-args args))
        (n (string->symbol (or lisp-name (clean-up-name name)))))
    (if (setterp name)
         `(progn (defun (setf ,n) (,@(last args) ,@(butlast args))
                  (multiple-value-bind (suc id res) (funcall #'send-command ,name ,@args)
                    res)))
         `(progn (defun ,n ,args
                  (multiple-value-bind (suc id res) (funcall #'send-command ,name ,@args)
                    res))
                 (export ',n :cl-neovim)))))

(desc->lisp-function "window_get_buffer" (("Window" "window")) "Buffer" T NIL)
(desc->lisp-function "window_get_cursor" (("Window" "window"))
                     "ArrayOf(Integer, 2)" T NIL)
(desc->lisp-function "window_set_cursor"
                     (("Window" "window") ("ArrayOf(Integer, 2)" "pos")) "void" T
                     T)
(desc->lisp-function "window_get_height" (("Window" "window")) "Integer" T NIL)
(desc->lisp-function "window_set_height"
                     (("Window" "window") ("Integer" "height")) "void" T T)
(desc->lisp-function "window_get_width" (("Window" "window")) "Integer" T NIL)
(desc->lisp-function "window_set_width" (("Window" "window") ("Integer" "width"))
                     "void" T T)
(desc->lisp-function "window_get_var" (("Window" "window") ("String" "name"))
                     "Object" T NIL)
(desc->lisp-function "window_set_var"
                     (("Window" "window") ("String" "name") ("Object" "value"))
                     "Object" T T)
(desc->lisp-function "window_get_option" (("Window" "window") ("String" "name"))
                     "Object" T NIL)
(desc->lisp-function "window_set_option"
                     (("Window" "window") ("String" "name") ("Object" "value"))
                     "void" T T)
(desc->lisp-function "window_get_position" (("Window" "window"))
                     "ArrayOf(Integer, 2)" T NIL)
(desc->lisp-function "window_get_tabpage" (("Window" "window")) "Tabpage" T NIL)
(desc->lisp-function "window_is_valid" (("Window" "window")) "Boolean" NIL NIL)
(desc->lisp-function "vim_command" (("String" "str")) "void" T T)
(desc->lisp-function "vim_feedkeys"
                     (("String" "keys") ("String" "mode")
                                        ("Boolean" "escape_csi"))
                     "void" NIL T)
(desc->lisp-function "vim_input" (("String" "keys")) "Integer" NIL NIL)
(desc->lisp-function "vim_replace_termcodes"
                     (("String" "str") ("Boolean" "from_part")
                                       ("Boolean" "do_lt") ("Boolean" "special"))
                     "String" NIL NIL)
(desc->lisp-function "vim_command_output" (("String" "str")) "String" T NIL)
(desc->lisp-function "vim_eval" (("String" "str")) "Object" T T "vim-eval")
(desc->lisp-function "vim_strwidth" (("String" "str")) "Integer" T NIL)
(desc->lisp-function "vim_list_runtime_paths" NIL "ArrayOf(String)" NIL NIL)
(desc->lisp-function "vim_change_directory" (("String" "dir")) "void" T NIL)
(desc->lisp-function "vim_get_current_line" NIL "String" T NIL)
(desc->lisp-function "vim_set_current_line" (("String" "line")) "void" T T)
(desc->lisp-function "vim_del_current_line" NIL "void" T T)
(desc->lisp-function "vim_get_var" (("String" "name")) "Object" T NIL)
(desc->lisp-function "vim_set_var" (("String" "name") ("Object" "value"))
                     "Object" T T)
(desc->lisp-function "vim_get_vvar" (("String" "name")) "Object" T NIL)
(desc->lisp-function "vim_get_option" (("String" "name")) "Object" T NIL)
(desc->lisp-function "vim_set_option" (("String" "name") ("Object" "value"))
                     "void" T T)
(desc->lisp-function "vim_out_write" (("String" "str")) "void" NIL T)
(desc->lisp-function "vim_err_write" (("String" "str")) "void" NIL T)
(desc->lisp-function "vim_report_error" (("String" "str")) "void" NIL T)
(desc->lisp-function "vim_get_buffers" NIL "ArrayOf(Buffer)" NIL NIL)
(desc->lisp-function "vim_get_current_buffer" NIL "Buffer" NIL NIL)
(desc->lisp-function "vim_set_current_buffer" (("Buffer" "buffer")) "void" T T)
(desc->lisp-function "vim_get_windows" NIL "ArrayOf(Window)" NIL NIL)
(desc->lisp-function "vim_get_current_window" NIL "Window" NIL NIL)
(desc->lisp-function "vim_set_current_window" (("Window" "window")) "void" T T)
(desc->lisp-function "vim_get_tabpages" NIL "ArrayOf(Tabpage)" NIL NIL)
(desc->lisp-function "vim_get_current_tabpage" NIL "Tabpage" NIL NIL)
(desc->lisp-function "vim_set_current_tabpage" (("Tabpage" "tabpage")) "void" T
                     T)
(desc->lisp-function "vim_subscribe" (("String" "event")) "void" NIL NIL)
(desc->lisp-function "vim_unsubscribe" (("String" "event")) "void" NIL NIL)
(desc->lisp-function "vim_name_to_color" (("String" "name")) "Integer" NIL NIL)
(desc->lisp-function "vim_get_color_map" NIL "Dictionary" NIL NIL)
(desc->lisp-function "vim_get_api_info" NIL "Array" NIL NIL)
(desc->lisp-function "tabpage_get_windows" (("Tabpage" "tabpage"))
                     "ArrayOf(Window)" T NIL)
(desc->lisp-function "tabpage_get_var" (("Tabpage" "tabpage") ("String" "name"))
                     "Object" T NIL)
(desc->lisp-function "tabpage_set_var"
                     (("Tabpage" "tabpage") ("String" "name") ("Object" "value"))
                     "Object" T T)
(desc->lisp-function "tabpage_get_window" (("Tabpage" "tabpage")) "Window" T NIL)
(desc->lisp-function "tabpage_is_valid" (("Tabpage" "tabpage")) "Boolean" NIL
                     NIL)
(desc->lisp-function "buffer_line_count" (("Buffer" "buffer")) "Integer" T NIL)
(desc->lisp-function "buffer_get_line" (("Buffer" "buffer") ("Integer" "index"))
                     "String" T NIL)
(desc->lisp-function "buffer_set_line"
                     (("Buffer" "buffer") ("Integer" "index") ("String" "line"))
                     "void" T T)
(desc->lisp-function "buffer_del_line" (("Buffer" "buffer") ("Integer" "index"))
                     "void" T T)
(desc->lisp-function "buffer_get_line_slice"
                     (("Buffer" "buffer") ("Integer" "start") ("Integer" "end")
                                          ("Boolean" "include_start") ("Boolean" "include_end"))
                     "ArrayOf(String)" T NIL)
(desc->lisp-function "buffer_set_line_slice"
                     (("Buffer" "buffer") ("Integer" "start") ("Integer" "end")
                                          ("Boolean" "include_start") ("Boolean" "include_end")
                                          ("ArrayOf(String)" "replacement"))
                     "void" T T)
(desc->lisp-function "buffer_get_var" (("Buffer" "buffer") ("String" "name"))
                     "Object" T NIL)
(desc->lisp-function "buffer_set_var"
                     (("Buffer" "buffer") ("String" "name") ("Object" "value"))
                     "Object" T T)
(desc->lisp-function "buffer_get_option" (("Buffer" "buffer") ("String" "name"))
                     "Object" T NIL)
(desc->lisp-function "buffer_set_option"
                     (("Buffer" "buffer") ("String" "name") ("Object" "value"))
                     "void" T T)
(desc->lisp-function "buffer_get_number" (("Buffer" "buffer")) "Integer" T NIL)
(desc->lisp-function "buffer_get_name" (("Buffer" "buffer")) "String" T NIL)
(desc->lisp-function "buffer_set_name" (("Buffer" "buffer") ("String" "name"))
                     "void" T T)
(desc->lisp-function "buffer_is_valid" (("Buffer" "buffer")) "Boolean" NIL NIL)
(desc->lisp-function "buffer_insert"
                     (("Buffer" "buffer") ("Integer" "lnum")
                                          ("ArrayOf(String)" "lines"))
                     "void" T T)
(desc->lisp-function "buffer_get_mark" (("Buffer" "buffer") ("String" "name"))
                     "ArrayOf(Integer, 2)" T NIL)
