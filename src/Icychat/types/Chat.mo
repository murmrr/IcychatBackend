import Buffer "mo:base/Buffer";
import Random "mo:base/Random";
import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";

import Message "Message";
import StableBuffer "StableBuffer";
import StableHashMap "FunctionalStableHashMap";

module {
  public type Chat = {
    id : Nat;
    keys : StableHashMap.StableHashMap<Principal, Text>;
    users : StableBuffer.StableBuffer<Principal>;
    messages : StableBuffer.StableBuffer<Message.Message>;
  };

  let ID_P : Nat8 = 64;

  public func construct(seed : Blob, user1 : Principal, user2 : Principal, user1Key : Text, user2Key : Text) : Chat {
    let users0Temp : StableBuffer.StableBuffer<Principal> = StableBuffer.init<Principal>();
    StableBuffer.add(users0Temp, user1);
    StableBuffer.add(users0Temp, user2);

    let keys0 : StableHashMap.StableHashMap<Principal, Text> = StableHashMap.init<Principal, Text>();
    StableHashMap.put(keys0, Principal.equal, Principal.hash, user1, user1Key);
    StableHashMap.put(keys0, Principal.equal, Principal.hash, user2, user2Key);
    return {
      id = Random.rangeFrom(ID_P, seed);
      keys = keys0;
      users = users0Temp;
      messages = StableBuffer.init<Message.Message>();
    };
  };
};
