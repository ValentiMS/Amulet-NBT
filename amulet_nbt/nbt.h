#include <map>
#include <string>
#include <memory>
#include <variant>


// raw objects
typedef int8_t ByteTag;
typedef int16_t ShortTag;
typedef int32_t IntTag;
typedef int64_t LongTag;
typedef float FloatTag;
typedef double DoubleTag;
typedef std::vector<ByteTag> ByteArrayTag;
typedef std::string StringTag;
class ListTag;  // forward declaration
class CompoundTag;  // forward declaration
typedef std::vector<IntTag> IntArrayTag;
typedef std::vector<LongTag> LongArrayTag;

// shared pointers to raw objects
typedef std::shared_ptr<ByteTag> SharedByteTag;
typedef std::shared_ptr<ShortTag> SharedShortTag;
typedef std::shared_ptr<IntTag> SharedIntTag;
typedef std::shared_ptr<LongTag> SharedLongTag;
typedef std::shared_ptr<FloatTag> SharedFloatTag;
typedef std::shared_ptr<DoubleTag> SharedDoubleTag;
typedef std::shared_ptr<ByteArrayTag> SharedByteArrayTag;
typedef std::shared_ptr<StringTag> SharedStringTag;
typedef std::shared_ptr<ListTag> SharedListTag;
typedef std::shared_ptr<CompoundTag> SharedCompoundTag;
typedef std::shared_ptr<IntArrayTag> SharedIntArrayTag;
typedef std::shared_ptr<LongArrayTag> SharedLongArrayTag;

// lists containing shared pointers to raw objects
typedef std::list<SharedByteTag> SharedByteTagList;
typedef std::list<SharedShortTag> SharedShortTagList;
typedef std::list<SharedIntTag> SharedIntTagList;
typedef std::list<SharedLongTag> SharedLongTagList;
typedef std::list<SharedFloatTag> SharedFloatTagList;
typedef std::list<SharedDoubleTag> SharedDoubleTagList;
typedef std::list<SharedByteArrayTag> SharedByteArrayTagList;
typedef std::list<SharedStringTag> SharedStringTagList;
typedef std::list<SharedListTag> SharedListTagList;
typedef std::list<SharedCompoundTag> SharedCompoundTagList;
typedef std::list<SharedIntArrayTag> SharedIntArrayTagList;
typedef std::list<SharedLongArrayTag> SharedLongArrayTagList;

class ListTag : public std::variant<
    std::monostate,
    SharedByteTagList,
    SharedShortTagList,
    SharedIntTagList,
    SharedLongTagList,
    SharedFloatTagList,
    SharedDoubleTagList,
    SharedByteArrayTagList,
    SharedStringTagList,
    SharedListTagList,
    SharedCompoundTagList,
    SharedIntArrayTagList,
    SharedLongArrayTagList
>
{
    using variant::variant;
};

class CompoundTagValue : public std::variant<
    std::monostate,
    SharedByteTag,
    SharedShortTag,
    SharedIntTag,
    SharedLongTag,
    SharedFloatTag,
    SharedDoubleTag,
    SharedByteArrayTag,
    SharedStringTag,
    SharedListTag,
    SharedCompoundTag,
    SharedIntArrayTag,
    SharedLongArrayTag
>
{
    using variant::variant;
};

class CompoundTag : public std::map<std::string, CompoundTagValue>
{
    using map::map;
};
