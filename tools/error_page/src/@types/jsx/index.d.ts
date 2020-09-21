/* eslint-disable functional/prefer-readonly-type */
interface FallbackImage extends React.SVGProps<SVGImageElement> {
  readonly src: string;
}

declare namespace JSX {
  interface IntrinsicElements {
    image: FallbackImage;
  }
}
