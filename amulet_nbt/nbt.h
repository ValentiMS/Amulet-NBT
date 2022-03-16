#include <map>
#include <string>
#include <memory>
#include <variant>
#include <vector>

// The standard vector class can be resized.
// To make wrapping in numpy easier we will make the size fixed at runtime.
template<class T>
class Array : private std::vector<T>
{
    public:
        // only methods that do not change the buffer size should be exposed here
        using std::vector<T>::value_type;
        using std::vector<T>::size_type;
        using std::vector<T>::difference_type;
        using std::vector<T>::iterator;
        using std::vector<T>::const_iterator;
        using std::vector<T>::reverse_iterator;
        using std::vector<T>::const_reverse_iterator;

        using std::vector<T>::vector;

        using std::vector<T>::operator[];
        using std::vector<T>::at;
        using std::vector<T>::back;
        using std::vector<T>::begin;
        using std::vector<T>::empty;
        using std::vector<T>::end;
        using std::vector<T>::front;
        using std::vector<T>::max_size;
        using std::vector<T>::size;
        using std::vector<T>::data;
};


// raw objects
typedef int8_t RawByteTag;
typedef int16_t RawShortTag;
typedef int32_t RawIntTag;
typedef int64_t RawLongTag;
typedef float RawFloatTag;
typedef double RawDoubleTag;
typedef Array<RawByteTag> RawByteArrayTag;
typedef std::string RawStringTag;
class RawListTag;  // forward declaration
class RawCompoundTag;  // forward declaration
typedef Array<RawIntTag> RawIntArrayTag;
typedef Array<RawLongTag> RawLongArrayTag;

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
