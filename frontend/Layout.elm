module Layout exposing (..)

import Accessibility as H exposing (Html)
import Accessibility.Live exposing (livePolite, relevantAdditions)
import Fifo
import Html.Attributes as A
import Html.Events as E
import Shared


layout : (Shared.Msg -> msg) -> Shared.Model -> Html msg -> Html msg
layout toMsg shared body =
    H.div
        []
        [ body
        , H.div
            [ A.class "absolute top-0 right-0 pt2 pr2"
            ]
            [ H.div
                [ A.class "flex flex-column items-end"
                , livePolite
                , relevantAdditions
                ]
                (shared.errors
                    |> Fifo.toList
                    |> List.map
                        (\errText ->
                            H.div
                                [ A.class "notification is-danger max-width-1"
                                ]
                                [ H.text errText
                                , H.button
                                    [ A.class "delete"
                                    , E.onClick <| Shared.HideError errText
                                    ]
                                    []
                                ]
                        )
                )
            ]
            |> H.map toMsg
        ]
