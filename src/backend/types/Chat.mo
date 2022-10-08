import Buffer "mo:base/Buffer";
import Random "mo:base/Random";
import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";

import Message "Message";

module {
  public type Chat = {
    id : Nat;
    keys : HashMap.HashMap<Principal, Text>;
    users : Buffer.Buffer<Principal>;
    messages : Buffer.Buffer<Message.Message>;
  };

  let ID_P : Nat8 =  64;

  public func construct(seed : Blob, user1 : Principal, user2 : Principal, user1Key : Text, user2Key : Text) : Chat {
    let users0Temp : Buffer.Buffer<Principal> = Buffer.Buffer<Principal>(0);
    users0Temp.add(user1);
    users0Temp.add(user2);

    let keys0 : HashMap.HashMap<Principal, Text> = HashMap.HashMap(0, Principal.equal, Principal.hash);
    keys0.put(user1, user1Key);
    keys0.put(user2, user2Key);
    return {
      id = Random.rangeFrom(ID_P, seed);
      keys = keys0;
      users = users0Temp;
      messages = Buffer.Buffer<Message.Message>(0);
    };
  };
};
