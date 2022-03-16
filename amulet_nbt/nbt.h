#include <unordered_map>
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
typedef std::shared_ptr<RawByteTag> CByteTag;
typedef std::shared_ptr<RawShortTag> CShortTag;
typedef std::shared_ptr<RawIntTag> CIntTag;
typedef std::shared_ptr<RawLongTag> CLongTag;
typedef std::shared_ptr<RawFloatTag> CFloatTag;
typedef std::shared_ptr<RawDoubleTag> CDoubleTag;
typedef std::shared_ptr<RawByteArrayTag> CByteArrayTag;
typedef std::shared_ptr<RawStringTag> CStringTag;
typedef std::shared_ptr<RawListTag> CListTag;
typedef std::shared_ptr<RawCompoundTag> CCompoundTag;
typedef std::shared_ptr<RawIntArrayTag> CIntArrayTag;
typedef std::shared_ptr<RawLongArrayTag> CLongArrayTag;

// lists containing shared pointers to raw objects
typedef std::vector<CByteTag> ByteTagList;
typedef std::vector<CShortTag> ShortTagList;
typedef std::vector<CIntTag> IntTagList;
typedef std::vector<CLongTag> LongTagList;
typedef std::vector<CFloatTag> FloatTagList;
typedef std::vector<CDoubleTag> DoubleTagList;
typedef std::vector<CByteArrayTag> ByteArrayTagList;
typedef std::vector<CStringTag> StringTagList;
typedef std::vector<CListTag> ListTagList;
typedef std::vector<CCompoundTag> CompoundTagList;
typedef std::vector<CIntArrayTag> IntArrayTagList;
typedef std::vector<CLongArrayTag> LongArrayTagList;

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
    CByteTag,
    CShortTag,
    CIntTag,
    CLongTag,
    CFloatTag,
    CDoubleTag,
    CByteArrayTag,
    CStringTag,
    CListTag,
    CCompoundTag,
    CIntArrayTag,
    CLongArrayTag
>
{
    using variant::variant;
};

class RawCompoundTag : public std::unordered_map<std::string, CompoundTagValue>
{
    using unordered_map::unordered_map;
};
