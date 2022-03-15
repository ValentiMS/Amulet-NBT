cdef extern from "<variant>" namespace "std" nogil:
    cdef cppclass variant:
        variant& operator=(variant&)

        # value status
        bint valueless_by_exception()
        size_t index()

    cdef struct monostate

    cdef T* get_if[T](...)
