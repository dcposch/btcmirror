interface JsonRpcOpts {
  url: string;
  headers: { [key: string]: string };
}

interface JsonRpcReq {
  jsonrpc: "2.0";
  id: number;
  method: string;
  params: any[] | Record<string, any>;
}

interface JsonRpcRes {
  jsonrpc: "2.0";
  id: number | string;
  result?: any;
  error?: { code: number; message: string; data?: any };
}

export class JsonRpcClient {
  nextID = 1;
  options: JsonRpcOpts;
  constructor(options: JsonRpcOpts) {
    this.options = options;
  }

  async req(
    method: string,
    params: any[] | Record<string, any>
  ): Promise<JsonRpcRes> {
    const { url, headers } = this.options;
    const req: JsonRpcReq = {
      id: this.nextID++,
      jsonrpc: "2.0",
      method,
      params,
    };

    const res = await fetch(url, {
      method: "POST",
      headers: { ...headers, "Content-Type": "application/json" },
      body: JSON.stringify(req),
    });

    let ret = null as JsonRpcRes | null;
    try {
      ret = (await res.json()) as JsonRpcRes;
      if (ret.id !== req.id) throw new Error("id mismatch");
      return ret;
    } catch (e) {
      throw new Error(
        `JSONRPC method ${method} error ${e}, ` +
          `${url} sent ${res.status} ${res.statusText}, ` +
          `request ${JSON.stringify(req)}, response ${JSON.stringify(ret)}`
      );
    }
  }
}
