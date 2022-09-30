import Buffer "mo:base/Buffer";
import Random "mo:base/Random";

import Message "Message";

module {
  public type Chat = {
    id : Nat;
    users : [Principal];
    messages : Buffer.Buffer<Message.Message>;
  };

  let ID_P : Nat8 =  64;

  public func construct(seed : Blob, users0 : [Principal]) : Chat {
    return {
      id = Random.rangeFrom(ID_P, seed);
      users = users0;
      messages = Buffer.Buffer<Message.Message>(0);
    };
  };
};
