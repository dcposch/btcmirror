// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import "./BtcMirror.sol";

//
//                                        #
//                                       # #
//                                      # # #
//                                     # # # #
//                                    # # # # #
//                                   # # # # # #
//                                  # # # # # # #
//                                 # # # # # # # #
//                                # # # # # # # # #
//                               # # # # # # # # # #
//                              # # # # # # # # # # #
//                                   # # # # # #
//                               +        #        +
//                                ++++         ++++
//                                  ++++++ ++++++
//                                    +++++++++
//                                      +++++
//                                        +
//
// BtcVerifier implements a Merkle proof that a Bitcoin payment succeeded. It
// uses BtcMirror as a source of truth for which Bitcoin block hashes are in the
// canonical chain.
contract BtcVerifier {
    BtcMirror immutable mirror;

    constructor(address _mirror) {
        mirror = BtcMirror(_mirror);
    }

    function verify(int256 blockNum, bytes calldata proof)
        public
        view
        returns (bool)
    {
        // TODO
    }
}
