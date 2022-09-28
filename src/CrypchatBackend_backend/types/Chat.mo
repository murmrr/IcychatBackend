import Buffer "mo:base/Buffer";
import Random "mo:base/Random";

import Message "Message";

module {
  public type Chat = {
    id : Nat8;
    users : [Principal];
    messages : Buffer.Buffer<Message.Message>;
  };

  public func construct(seed : Blob, users0 : [Principal]) : Chat {
      return {
        id = Random.byteFrom(seed);
        users = users0;
        messages = Buffer.Buffer<Message.Message>(0);
      };
  };
};
