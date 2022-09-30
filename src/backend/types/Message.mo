import Time "mo:base/Time";
import Random "mo:base/Random";

import MessageContent "MessageContent";

module {
  public type Message = {
    id : Nat;
    time : Time.Time;
    sender : Principal;
    content : MessageContent.MessageContent;
  };

  let ID_P : Nat8 =  64;

  public func construct(seed : Blob, sender0 : Principal, content0 : MessageContent.MessageContent) : Message {
    return {
      id = Random.rangeFrom(ID_P, seed);
      time = Time.now();
      sender = sender0;
      content = content0;
    };
  };
};
