import AMM from '../components/layout/amm.layout';
import { ConnectButton } from '@rainbow-me/rainbowkit';
import Head from 'next/head';
import type { NextPage } from 'next';
import { ethers } from 'ethers';
import styles from '../styles/Home.module.css';

const Home: NextPage = () => {

  return (
    <div className={styles.container}>
      <Head>
        <title>Swipe</title>
        <meta
          content="Liquidity in your hand, one stop for all tokens"
          name="description"
        />
        <link href="/favicon.ico" rel="icon" />
      </Head>

      <main className={styles.main}>
        <ConnectButton />

        <h1 className={styles.title}>
          2 Token AMM
        </h1>
        <AMM />
      </main>
    </div>
  );
};

export default Home;
