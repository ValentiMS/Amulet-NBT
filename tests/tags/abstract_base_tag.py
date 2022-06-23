import unittest
from abc import ABC, abstractmethod

from amulet_nbt import (
    ByteTag,
    ShortTag,
    IntTag,
    LongTag,
    FloatTag,
    DoubleTag,
    ByteArrayTag,
    IntArrayTag,
    LongArrayTag,
    StringTag,
    ListTag,
    CompoundTag,
)


class AbstractBaseTagTest:
    class AbstractBaseTagTest(unittest.TestCase, ABC):
        def setUp(self):
            self.int_types = (
                ByteTag,
                ShortTag,
                IntTag,
                LongTag,
            )
            self.float_types = (
                FloatTag,
                DoubleTag,
            )
            self.numerical_types = self.int_types + self.float_types
            self.string_types = (StringTag,)
            self.array_types = (
                ByteArrayTag,
                IntArrayTag,
                LongArrayTag,
            )
            self.container_types = (
                ListTag,
                CompoundTag,
            )
            self.nbt_types = (
                self.numerical_types
                + self.string_types
                + self.array_types
                + self.container_types
            )

            self.not_nbt = (None, True, False, 0, 0.0, "str", [], {}, set())

        @abstractmethod
        def test_constructor(self):
            raise NotImplementedError

        @abstractmethod
        def test_equal(self):
            raise NotImplementedError

        @abstractmethod
        def test_py_data(self):
            raise NotImplementedError

        @abstractmethod
        def test_copy(self):
            raise NotImplementedError

        @abstractmethod
        def test_pickle(self):
            raise NotImplementedError

        @abstractmethod
        def test_instance(self):
            raise NotImplementedError

        @abstractmethod
        def test_hash(self):
            raise NotImplementedError

        @abstractmethod
        def test_repr(self):
            raise NotImplementedError


if __name__ == "__main__":
    unittest.main()
