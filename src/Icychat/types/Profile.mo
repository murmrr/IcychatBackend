import Hash "mo:base/Hash";
import Principal "mo:base/Principal";

import AssetMap "../actors/AssetMap";

import ProfileUpdate "ProfileUpdate";

module {
  public type Profile = {
    userPrincipal : Principal;
    assetMap : AssetMap.AssetMap;
    username : Text;
  };

  public func getDefault(userPrincipal0 : Principal, assetMap0 : AssetMap.AssetMap) : Profile {
    return {
      userPrincipal = userPrincipal0;
      assetMap = assetMap0;
      username = "";
    };
  };

  public func update(old : Profile, new : ProfileUpdate.ProfileUpdate) : Profile {
    return {
      userPrincipal = old.userPrincipal;
      assetMap = old.assetMap;
      username = new.username;
    };
  };
};
