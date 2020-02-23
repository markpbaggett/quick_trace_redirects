Quick Trace Redirects
=====================

.. image:: https://github.com/markpbaggett/quick_trace_redirects/workflows/Build%20and%20Test/badge.svg
  :alt: Github Build and Test Badge
  :width: 40%
.. image:: https://github.com/markpbaggett/quick_trace_redirects/workflows/Release%20and%20Publish/badge.svg
  :alt: Github Release and Publish Badge
  :width: 40%

An alternative to `trace migrater's <https://github.com/markpbaggett/trace_migrater>`_ redirect module. This is built around OAI-PMH instead of the Digital Commons frontend making it much faster.

Build and Install
-----------------

The latest release is available in the `Releases <https://github.com/markpbaggett/quick_trace_redirects/releases>`_ tab.

If you are unable to use it, you can:

1. First, follow the instructions `here <https://nim-lang.org/install.html>`_ to install nim. Using choosenim is recommended.
2. Make sure you set your PATH appropriately so that nim and nimble can be found.
3. Make sure you have a c compiler like gcc or musl (if not, you'll get an error in step 6).
4. git clone git@github.com:markpbaggett/quick_trace_redirects.git
5. cd moldybread
6. nimble install
