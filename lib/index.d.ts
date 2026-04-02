interface Connection<A extends unknown[], V extends unknown[]> {
  Connected: boolean;
  Disconnect(): void;
  Reconnect(): void;
}

interface Signal<A extends unknown[]> {
  Connect<V extends unknown[]>(
    fn: (...args: [...A, ...V]) => void,
    ...boundArgs: V
  ): Connection<A, V>;

  Once<V extends unknown[]>(
    fn: (...args: [...A, ...V]) => void,
    ...boundArgs: V
  ): Connection<A, V>;

  Wait(timeout?: number): [...A];

  Fire(...args: A): void;

  DisconnectAll(): void;

  Destroy(): void;
}

interface AcidSignal {
  new <A extends unknown[]>(): Signal<A>;
}

declare const AcidSignal: AcidSignal;
export = AcidSignal;
