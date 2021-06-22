module Page.NotAllowed exposing (..)

import Accessibility as H exposing (Html)
import Html.Attributes as A


view : H.Html msg
view =
    H.div
        [ A.class "max-width-4 mx-auto p2"
        , A.id pageId
        ]
        [ H.text "Not Allowed"
        , H.br []
        , H.a
            [ A.href "/" ]
            [ H.text "Go back home" ]
        ]


pageId =
    "not-allowed-page"
