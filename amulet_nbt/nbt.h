#include <map>
#include <string>
#include <memory>
#include <variant>


// raw objects
typedef int8_t RawByteTag;
typedef int16_t RawShortTag;
typedef int32_t RawIntTag;
typedef int64_t RawLongTag;
typedef float RawFloatTag;
typedef double RawDoubleTag;
typedef std::vector<RawByteTag> RawByteArrayTag;
typedef std::string RawStringTag;
class RawListTag;  // forward declaration
class RawCompoundTag;  // forward declaration
typedef std::vector<RawIntTag> RawIntArrayTag;
typedef std::vector<RawLongTag> RawLongArrayTag;

// shared pointers to raw objects
typedef std::shared_ptr<RawByteTag> ByteTag;
typedef std::shared_ptr<RawShortTag> ShortTag;
typedef std::shared_ptr<RawIntTag> IntTag;
typedef std::shared_ptr<RawLongTag> LongTag;
typedef std::shared_ptr<RawFloatTag> FloatTag;
typedef std::shared_ptr<RawDoubleTag> DoubleTag;
typedef std::shared_ptr<RawByteArrayTag> ByteArrayTag;
typedef std::shared_ptr<RawStringTag> StringTag;
typedef std::shared_ptr<RawListTag> ListTag;
typedef std::shared_ptr<RawCompoundTag> CompoundTag;
typedef std::shared_ptr<RawIntArrayTag> IntArrayTag;
typedef std::shared_ptr<RawLongArrayTag> LongArrayTag;

// lists containing shared pointers to raw objects
typedef std::list<ByteTag> ByteTagList;
typedef std::list<ShortTag> ShortTagList;
typedef std::list<IntTag> IntTagList;
typedef std::list<LongTag> LongTagList;
typedef std::list<FloatTag> FloatTagList;
typedef std::list<DoubleTag> DoubleTagList;
typedef std::list<ByteArrayTag> ByteArrayTagList;
typedef std::list<StringTag> StringTagList;
typedef std::list<ListTag> ListTagList;
typedef std::list<CompoundTag> CompoundTagList;
typedef std::list<IntArrayTag> IntArrayTagList;
typedef std::list<LongArrayTag> LongArrayTagList;

class RawListTag : public std::variant<
    std::monostate,
    ByteTagList,
    ShortTagList,
    IntTagList,
    LongTagList,
    FloatTagList,
    DoubleTagList,
    ByteArrayTagList,
    StringTagList,
    ListTagList,
    CompoundTagList,
    IntArrayTagList,
    LongArrayTagList
>
{
    using variant::variant;
};

class CompoundTagValue : public std::variant<
    std::monostate,
    ByteTag,
    ShortTag,
    IntTag,
    LongTag,
    FloatTag,
    DoubleTag,
    ByteArrayTag,
    StringTag,
    ListTag,
    CompoundTag,
    IntArrayTag,
    LongArrayTag
>
{
    using variant::variant;
};

class RawCompoundTag : public std::map<std::string, CompoundTagValue>
{
    using map::map;
};
