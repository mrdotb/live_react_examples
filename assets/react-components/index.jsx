// polyfill recommended by Vite https://vitejs.dev/config/build-options#build-modulepreload
import "vite/modulepreload-polyfill";

import { CodeBlock } from "./examples/CodeBlock";
import { Context as ExampleContext } from "./examples/Context";
import { Counter as ExampleCounter } from "./examples/Counter";
import { Events as ExampleEvents } from "./examples/Events";
import { FileUpload as ExampleFileUpload } from "./examples/FileUpload";
import { HybridForm as ExampleHybridForm } from "./examples/HybridForm";
import { LinkExample } from "./examples/Link";
import { LinkDemo as ExampleLinkDemo } from "./examples/LinkDemo";
import { PropsDiffing as ExamplePropsDiffing } from "./examples/PropsDiffing";
import { ServerEvents as ExampleServerEvents } from "./examples/ServerEvents";
import { Simple as ExampleSimple } from "./examples/Simple";
import { SimpleProps as ExampleSimpleProps } from "./examples/SimpleProps";
import { Slots as ExampleSlots } from "./examples/Slots";
import { SSR as ExampleSSR } from "./examples/SSR";
import { Streams as ExampleStreams } from "./examples/Streams";
import { Lazy as ExampleLazy } from "./examples/Lazy";
import { Typescript as ExampleTypescript } from "./examples/Typescript";

export default {
  "examples/CodeBlock": CodeBlock,
  "examples/Context": ExampleContext,
  "examples/Counter": ExampleCounter,
  "examples/Events": ExampleEvents,
  "examples/FileUpload": ExampleFileUpload,
  "examples/HybridForm": ExampleHybridForm,
  "examples/Lazy": ExampleLazy,
  "examples/Link": LinkExample,
  "examples/LinkDemo": ExampleLinkDemo,
  "examples/PropsDiffing": ExamplePropsDiffing,
  "examples/ServerEvents": ExampleServerEvents,
  "examples/Simple": ExampleSimple,
  "examples/SimpleProps": ExampleSimpleProps,
  "examples/Slots": ExampleSlots,
  "examples/SSR": ExampleSSR,
  "examples/Streams": ExampleStreams,
  "examples/Typescript": ExampleTypescript,
};
