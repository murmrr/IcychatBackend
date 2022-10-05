import Buffer "mo:base/Buffer";
import Random "mo:base/Random";

import Message "Message";

module {
  public type Chat = {
    id : Nat;
    users : Buffer.Buffer<Principal>;
    messages : Buffer.Buffer<Message.Message>;
  };

  let ID_P : Nat8 =  64;

  public func construct(seed : Blob, users0 : [Principal]) : Chat {
    let users0Temp : Buffer.Buffer<Principal> = Buffer.Buffer<Principal>(0);
    for (user in users0.vals()) {
      users0Temp.add(user);
    };
    return {
      id = Random.rangeFrom(ID_P, seed);
      users = users0Temp;
      messages = Buffer.Buffer<Message.Message>(0);
    };
  };
};
