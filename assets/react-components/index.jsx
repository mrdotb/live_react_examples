// polyfill recommended by Vite https://vitejs.dev/config/build-options#build-modulepreload
import "vite/modulepreload-polyfill";

import { Context } from "./context";
import { Counter } from "./counter";
import { CodeBlock } from "./examples/CodeBlock";
import { Counter as ExampleCounter } from "./examples/Counter";
import { Simple as ExampleSimple } from "./examples/Simple";
import { SimpleProps as ExampleSimpleProps } from "./examples/SimpleProps";
import { DelaySlider } from "./delay-slider";
import { FlashSonner } from "./flash-sonner";
import { GithubCode } from "./github-code";
import { Lazy } from "./lazy";
import { Lazy as ExampleLazy } from "./examples/Lazy";
import { Link } from "./link";
import { LinkExample } from "./link-example";
import { LogList } from "./log-list";
import { SSR } from "./ssr";
import { Simple } from "./simple";
import { SimpleProps } from "./simple-props";
import { Slot } from "./slot";
import { StreamDemo } from "./stream-demo";
import { Typescript } from "./typescript";
import { Typescript as ExampleTypescript } from "./examples/Typescript";

export default {
  Context,
  Counter,
  DelaySlider,
  "examples/CodeBlock": CodeBlock,
  "examples/Counter": ExampleCounter,
  "examples/Lazy": ExampleLazy,
  "examples/Simple": ExampleSimple,
  "examples/SimpleProps": ExampleSimpleProps,
  "examples/Typescript": ExampleTypescript,
  FlashSonner,
  GithubCode,
  Lazy,
  Link,
  LinkExample,
  LogList,
  SSR,
  Simple,
  SimpleProps,
  Slot,
  StreamDemo,
  Typescript,
};
