import type { NonEmptyArray } from "./helpers";

export interface Feature {
  title: string;
  content: string[];
  icon: string;
  products: NonEmptyArray<ProductName>;
}

export type ProductName = "lueur" | "reliably" | "chaostoolkit";

export interface PagerData {
  currentPage: number;
  lastPage: number;
  urlBase: string;
}

export interface PagerPage {
  number: number;
  url: string;
}
