import unittest
import itertools
import copy
import pickle

import numpy
import numpy.testing

from amulet_nbt import (
    __major__,
    AbstractBaseTag,
    AbstractBaseMutableTag,
    AbstractBaseArrayTag,
)

from tests.tags.abstract_base_tag import AbstractBaseTagTest


class TestArray(AbstractBaseTagTest.AbstractBaseTagTest):
    def test_constructor(self):
        for cls in self.array_types:
            with self.subTest(cls=cls):
                cls()
                cls([1, 2, 3])
                cls(numpy.array([1, 2, 3]))
                with self.assertRaises(TypeError):
                    cls(None)
                with self.assertRaises(ValueError):
                    cls("test")

            for cls2 in self.array_types:
                with self.subTest(cls=cls, cls2=cls2):
                    cls(cls2([1, 2, 3]))

    def test_equal(self):
        for cls1, cls2 in itertools.product(self.array_types, repeat=2):
            for arg1, arg2 in itertools.product(([], [1, 2, 3], [4, 5, 6]), repeat=2):
                with self.subTest(cls1=cls1, cls2=cls2, arg1=arg1, arg2=arg2):
                    a = cls1(arg1)
                    b = cls2(arg2)
                    if arg1 == arg2 and cls1 is cls2:
                        self.assertEqual(a, b)
                    elif __major__ <= 2 and arg1 == arg2:
                        self.assertEqual(a, b)
                    else:
                        self.assertNotEqual(a, b)

    def test_py_data(self):
        for cls in self.array_types:
            with self.subTest(cls=cls):
                inst = cls([1, 2, 3])
                arr = inst.np_array
                self.assertIsInstance(arr, numpy.ndarray)

                # should keep the same buffer
                arr[1] = 10
                self.assertEqual(10, inst[1])

    def test_set_get_item(self):
        for cls in self.array_types:
            with self.subTest("Get and set index", cls=cls):
                inst = cls([1, 2, 3])
                self.assertIsInstance(inst[0], numpy.signedinteger)
                self.assertEqual(1, inst[0])
                self.assertEqual(2, inst[1])
                self.assertEqual(3, inst[2])
                inst[1] = 10
                self.assertEqual(1, inst[0])
                self.assertEqual(10, inst[1])
                self.assertEqual(3, inst[2])

            with self.subTest("Get and set slice", cls=cls):
                inst = cls([1, 2, 3])
                self.assertIsInstance(inst[:], numpy.ndarray)
                numpy.testing.assert_array_equal([1, 2, 3], inst[:])
                numpy.testing.assert_array_equal([1, 3], inst[::2])
                inst[::2] = [4, 5]
                self.assertIsInstance(inst[:], numpy.ndarray)
                numpy.testing.assert_array_equal([4, 2, 5], inst[:])
                numpy.testing.assert_array_equal([4, 5], inst[::2])

    def test_copy(self):
        for cls in self.array_types:
            with self.subTest("Shallow Copy", cls=cls):
                # shallow copy should keep the same buffer
                inst = cls([1, 2, 3])
                inst2 = copy.copy(inst)
                self.assertEqual(inst, inst2)
                inst[1] = 10
                self.assertEqual(10, inst2[1])

            with self.subTest("Deep Copy", cls=cls):
                # deepcopy should create a new buffer
                inst = cls([1, 2, 3])
                inst2 = copy.deepcopy(inst)
                self.assertEqual(inst, inst2)
                inst[1] = 10
                self.assertNotEqual(10, inst2[1])

    def test_pickle(self):
        for cls1, cls2 in itertools.product(self.array_types, repeat=2):
            for arg1, arg2 in itertools.product(([], [1, 2, 3], [4, 5, 6]), repeat=2):
                with self.subTest(cls1=cls1, cls2=cls2, arg1=arg1, arg2=arg2):
                    a = cls1(arg1)
                    dump = pickle.dumps(cls2(arg2))
                    b = pickle.loads(dump)
                    if arg1 == arg2 and cls1 is cls2:
                        self.assertEqual(a, b)
                    elif __major__ <= 2 and arg1 == arg2:
                        self.assertEqual(a, b)
                    else:
                        self.assertNotEqual(a, b)

    def test_instance(self):
        for cls in self.array_types:
            for parent in (
                AbstractBaseTag,
                AbstractBaseMutableTag,
                AbstractBaseArrayTag,
                cls,
            ):
                with self.subTest(cls=cls, parent=parent):
                    self.assertIsInstance(cls(), parent)

    def test_hash(self):
        for cls in self.array_types:
            with self.subTest(cls=cls):
                with self.assertRaises(TypeError):
                    hash(cls())
                with self.assertRaises(TypeError):
                    hash(cls([1, 2, 3]))

    def test_repr(self):
        for cls in self.array_types:
            with self.subTest(cls=cls):
                self.assertEqual(f"{cls.__name__}([])", repr(cls()))
                self.assertEqual(f"{cls.__name__}([1, 2, 3])", repr(cls([1, 2, 3])))

    def test_len(self):
        for cls in self.array_types:
            with self.subTest(cls=cls):
                self.assertEqual(0, len(cls()))
                self.assertEqual(3, len(cls([1, 2, 3])))


if __name__ == "__main__":
    unittest.main()
