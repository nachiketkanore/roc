import { EventEpoch } from "../../engine/engine";
import { Variable } from "../../schema";
import { VariableElPretty } from "../Common/Variable";
import { CommonProps } from "./types";

interface VariableProps extends CommonProps {
  epoch: EventEpoch;
  variable: Variable;
}

export function VariableEl({
  engine,
  toggleVariableVis,
  epoch,
  variable,
}: VariableProps): JSX.Element {
  engine.stepTo(epoch);
  return (
    <VariableElPretty
      variable={variable}
      subs={engine.subs}
      onClick={(variable: Variable) => {
        toggleVariableVis(variable);
      }}
    ></VariableElPretty>
  );
}
