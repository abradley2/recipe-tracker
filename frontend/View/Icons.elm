module View.Icons exposing (..)

import Accessibility as H exposing (Html)
import Html.Attributes exposing (style)
import Svg
import Svg.Attributes as A


type alias Size =
    { width : String
    , height : String
    }


materialIconAttributes : Size -> List (H.Attribute msg)
materialIconAttributes size =
    [ A.viewBox "0 0 24 24"
    , style "height" size.height
    , style "width" size.width
    , A.fill "currentColor"
    ]


email : Size -> Html msg
email size =
    Svg.svg
        (materialIconAttributes size)
        [ Svg.path
            [ A.d "M12 1.95c-5.52 0-10 4.48-10 10s4.48 10 10 10h5v-2h-5c-4.34 0-8-3.66-8-8s3.66-8 8-8 8 3.66 8 8v1.43c0 .79-.71 1.57-1.5 1.57s-1.5-.78-1.5-1.57v-1.43c0-2.76-2.24-5-5-5s-5 2.24-5 5 2.24 5 5 5c1.38 0 2.64-.56 3.54-1.47.65.89 1.77 1.47 2.96 1.47 1.97 0 3.5-1.6 3.5-3.57v-1.43c0-5.52-4.48-10-10-10zm0 13c-1.66 0-3-1.34-3-3s1.34-3 3-3 3 1.34 3 3-1.34 3-3 3zs"
            ]
            []
        ]


syncing : Size -> Html msg
syncing size =
    Svg.svg
        (materialIconAttributes size ++ [ A.class "spin" ])
        [ Svg.path
            [ A.d "M12 4V1L8 5l4 4V6c3.31 0 6 2.69 6 6 0 1.01-.25 1.97-.7 2.8l1.46 1.46C19.54 15.03 20 13.57 20 12c0-4.42-3.58-8-8-8zm0 14c-3.31 0-6-2.69-6-6 0-1.01.25-1.97.7-2.8L5.24 7.74C4.46 8.97 4 10.43 4 12c0 4.42 3.58 8 8 8v3l4-4-4-4v3z" ]
            []
        ]
