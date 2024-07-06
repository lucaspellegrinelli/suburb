class SuburbClient {
    constructor(host, apiKey) {
        this.host = host;
        this.headers = {
            'Authorization': `${apiKey}`,
            'Content-Type': 'application/json'
        };
    }

    async listQueues() {
        const response = await fetch(`${this.host}/queues`, {
            method: 'GET',
            headers: this.headers
        });
        return response.json();
    }

    async createQueue(namespace, queue) {
        const data = { namespace, queue };
        const response = await fetch(`${this.host}/queues`, {
            method: 'POST',
            headers: this.headers,
            body: JSON.stringify(data)
        });
        return response.json();
    }

    async pushToQueue(ns, name, message) {
        const data = { message };
        const response = await fetch(`${this.host}/queues/${ns}/${name}`, {
            method: 'POST',
            headers: this.headers,
            body: JSON.stringify(data)
        });
        return response.json();
    }

    async deleteQueue(ns, name) {
        const response = await fetch(`${this.host}/queues/${ns}/${name}`, {
            method: 'DELETE',
            headers: this.headers
        });
        return response.json();
    }

    async peekQueue(ns, name) {
        const response = await fetch(`${this.host}/queues/${ns}/${name}/peek`, {
            method: 'GET',
            headers: this.headers
        });
        return response.json();
    }

    async popQueue(ns, name) {
        const response = await fetch(`${this.host}/queues/${ns}/${name}/pop`, {
            method: 'POST',
            headers: this.headers
        });
        return response.json();
    }

    async getQueueLength(ns, name) {
        const response = await fetch(`${this.host}/queues/${ns}/${name}/length`, {
            method: 'GET',
            headers: this.headers
        });
        return response.json();
    }

    async listFlags() {
        const response = await fetch(`${this.host}/flags`, {
            method: 'GET',
            headers: this.headers
        });
        return response.json();
    }

    async getFlag(ns, name) {
        const response = await fetch(`${this.host}/flags/${ns}/${name}`, {
            method: 'GET',
            headers: this.headers
        });
        return response.json();
    }

    async setFlag(ns, name, value) {
        const data = { value };
        const response = await fetch(`${this.host}/flags/${ns}/${name}`, {
            method: 'POST',
            headers: this.headers,
            body: JSON.stringify(data)
        });
        return response.json();
    }

    async deleteFlag(ns, name) {
        const response = await fetch(`${this.host}/flags/${ns}/${name}`, {
            method: 'DELETE',
            headers: this.headers
        });
        return response.json();
    }

    async listLogs() {
        const response = await fetch(`${this.host}/logs`, {
            method: 'GET',
            headers: this.headers
        });
        return response.json();
    }

    async addLog(ns, source, level, message) {
        const data = { source, level, message };
        const response = await fetch(`${this.host}/logs/${ns}`, {
            method: 'POST',
            headers: this.headers,
            body: JSON.stringify(data)
        });
        return response.json();
    }
}
