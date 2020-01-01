use bumpalo::collections::String;
use bumpalo::Bump;
use std::hash::{BuildHasherDefault, Hash};

pub use wyhash::WyHash;

#[inline(always)]
pub fn default_hasher() -> BuildHasherDefault<WyHash> {
    BuildHasherDefault::default()
}

pub type BuildHasher = BuildHasherDefault<WyHash>;

// Versions of HashMap and HashSet from both std and im_rc
// which use the FNV hasher instead of the default SipHash hasher.
// FNV is faster but less secure; that's fine, since this compiler
// doesn't need cryptographically secure hashes, and also is not a
// server concerned about hash flooding attacks!
pub type MutMap<K, V> = std::collections::HashMap<K, V, BuildHasher>;

pub type MutSet<K> = std::collections::HashSet<K, BuildHasher>;

pub type ImMap<K, V> = im_rc::hashmap::HashMap<K, V, BuildHasher>;

pub type ImSet<K> = im_rc::hashset::HashSet<K, BuildHasher>;

pub type SendMap<K, V> = im::hashmap::HashMap<K, V, BuildHasher>;

pub type SendSet<K> = im::hashset::HashSet<K, BuildHasher>;

pub fn arena_join<'a, I>(arena: &'a Bump, strings: &mut I, join_str: &str) -> String<'a>
where
    I: Iterator<Item = &'a str>,
{
    let mut buf = String::new_in(arena);

    if let Some(first) = strings.next() {
        buf.push_str(&first);

        for string in strings {
            buf.reserve(join_str.len() + string.len());

            buf.push_str(join_str);
            buf.push_str(string);
        }
    }

    buf
}

pub fn insert_all<K, V, I>(map: &mut ImMap<K, V>, elems: I)
where
    K: Clone + Eq + Hash,
    V: Clone,
    I: Iterator<Item = (K, V)>,
{
    for (k, v) in elems {
        map.insert(k, v);
    }
}
