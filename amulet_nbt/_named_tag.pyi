from ._value import AbstractBaseTag
from ._int import ByteTag, ShortTag, IntTag, LongTag
from ._float import FloatTag, DoubleTag
from ._string import StringTag
from ._list import ListTag
from ._compound import CompoundTag
from ._array import ByteArrayTag, IntArrayTag, LongArrayTag
from ._util import EncoderType
from mutf8 import encode_modified_utf8

class NamedTag:
    @property
    def name(self) -> str: ...
    @property
    def tag(self) -> AbstractBaseTag: ...
    def to_nbt(
        self,
        *,
        compressed: bool = True,
        little_endian: bool = False,
        string_encoder: EncoderType = encode_modified_utf8,
    ) -> bytes: ...
    def save_to(
        self,
        filepath_or_buffer=None,
        *,
        compressed: bool = True,
        little_endian: bool = False,
        string_encoder: EncoderType = encode_modified_utf8,
    ) -> bytes: ...
    def get_byte(self) -> ByteTag: ...
    def get_short(self) -> ShortTag: ...
    def get_int(self) -> IntTag: ...
    def get_long(self) -> LongTag: ...
    def get_float(self) -> FloatTag: ...
    def get_double(self) -> DoubleTag: ...
    def get_string(self) -> StringTag: ...
    def get_list(self) -> ListTag: ...
    def get_compound(self) -> CompoundTag: ...
    def get_byte_array(self) -> ByteArrayTag: ...
    def get_int_array(self) -> IntArrayTag: ...
    def get_long_array(self) -> LongArrayTag: ...
