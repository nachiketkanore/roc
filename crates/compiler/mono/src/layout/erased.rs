use roc_target::TargetInfo;

/// The layout of an erasure.
///
/// A type-erased value consists of three fields at runtime:
///
/// ```
/// {
///   // the material value being erased.
///   // if the erasure is a function, this is the captured environment, or null.
///   value: void*,
///
///   // if the erasure is a function, the function pointer, or null otherwise.
///   callee: void*,
///
///   // the refcounter for the material value, or null if there is no material value.
///   refcounter: void*,
/// }
/// ```
#[derive(Clone, Copy, Debug, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub struct Erased;

impl Erased {
    pub fn safe_to_memcpy(&self) -> bool {
        false
    }

    pub fn stack_size_without_alignment(&self, target_info: TargetInfo) -> u32 {
        (target_info.ptr_width() as u32) * 3
    }

    pub fn alignment_bytes(&self, target_info: TargetInfo) -> u32 {
        target_info.ptr_width() as u32
    }

    pub fn allocation_alignment_bytes(&self, target_info: TargetInfo) -> u32 {
        target_info.ptr_width() as u32
    }

    pub fn is_refcounted(&self) -> bool {
        // The refcounter may not be present, but we don't know that statically.
        // So assume we always refcount, and the implementor of the refcount function
        // can no-op if it's not needed.
        true
    }

    pub fn to_doc<'b, D, A>(&self, alloc: &'b D) -> ven_pretty::DocBuilder<'b, D, A>
    where
        D: ven_pretty::DocAllocator<'b, A>,
        D::Doc: Clone,
        A: Clone,
    {
        alloc.text("?Erased")
    }
}
