from .value cimport BaseImmutableTag
from math import floor, ceil


cdef class BaseNumericTag(BaseImmutableTag):
    def __repr__(self):
        return f"{self.__class__.__name__}({self.value_})"

    def __add__(self, other):
        return self.value_ + other

    def __radd__(self, other):
        return other + self.value_

    def __iadd__(self, other):
        return self.__class__(self + other)

    def __sub__(self, other):
        return self.value_ - other

    def __rsub__(self, other):
        return other - self.value_

    def __isub__(self, other):
        return self.__class__(self - other)

    def __mul__(self, other):
        return self.value_ * other

    def __rmul__(self, other):
        return other * self.value_

    def __imul__(self, other):
        return self.__class__(self * other)

    def __truediv__(self, other):
        return self.value_ / other

    def __rtruediv__(self, other):
        return other / self.value_

    def __itruediv__(self, other):
        return self.__class__(self / other)

    def __floordiv__(self, other):
        return self.value_ // other

    def __rfloordiv__(self, other):
        return other // self.value_

    def __ifloordiv__(self, other):
        return self.__class__(self // other)

    def __mod__(self, other):
        return self.value_ % other

    def __rmod__(self, other):
        return other % self.value_

    def __imod__(self, other):
        return self.__class__(self % other)

    def __divmod__(self, other):
        return divmod(self.value_, other)

    def __rdivmod__(self, other):
        return divmod(other, self.value_)

    def __pow__(self, power, modulo):
        return pow(self.value_, power, modulo)

    def __rpow__(self, other, modulo):
        return pow(other, self.value_, modulo)

    def __ipow__(self, other):
        return self.__class__(pow(self, other))

    def __neg__(self):
        return self.value_.__neg__()

    def __pos__(self):
        return self.value_.__pos__()

    def __abs__(self):
        return self.value_.__abs__()

    def __int__(self):
        return self.value_.__int__()

    def __float__(self):
        return self.value_.__float__()

    def __round__(self, n=None):
        return round(self.value_, n)

    def __trunc__(self):
        return self.value_.__trunc__()

    def __floor__(self):
        return floor(self.value_)

    def __ceil__(self):
        return ceil(self.value_)

    def __bool__(self):
        return self.value_.__bool__()
