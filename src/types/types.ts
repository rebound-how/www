import type { NonEmptyArray } from "./helpers";

export interface Feature {
  title: string;
  content: string[];
  icon: string;
  product: NonEmptyArray<ProductName>;
}

type ProductName = "lueur" | "reliably" | "chaostoolkit";
