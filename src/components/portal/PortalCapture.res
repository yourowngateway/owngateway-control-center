@react.component
let make = React.memo((~name: string, ~customStyle="") => {
  let setPortalNodes = Recoil.useSetRecoilState(PortalState.portalNodes)
  let setDiv = React.useCallback2((elem: Js.Nullable.t<Dom.element>) => {
    setPortalNodes(.
      prevDict => {
        let clonedDict =
          prevDict
          ->Js.Dict.entries
          ->Js.Array2.filter(
            entry => {
              let (key, _val) = entry
              key !== name
            },
          )
          ->Js.Dict.fromArray

        switch elem->Js.Nullable.toOption {
        | Some(elem) => Js.Dict.set(clonedDict, name, elem)
        | None => ()
        }

        clonedDict
      },
    )
  }, (setPortalNodes, name))

  <div className={`${customStyle}`} ref={ReactDOM.Ref.callbackDomRef(setDiv)} />
})
